import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:billing_app/core/error/failure.dart';
import 'package:billing_app/features/licensing/domain/entities/license_status.dart';
import 'package:billing_app/features/licensing/domain/entities/subscription_plan.dart';
import 'package:billing_app/features/licensing/domain/repositories/license_repository.dart';
import 'package:billing_app/features/licensing/presentation/bloc/license_bloc.dart';

/// The mid-session expiry lock: a subscription (trial or paid) that expires
/// while the app is open must flip the gate to unlicensed *by itself* — via
/// the bloc's expiry timer — not only on the next navigation or restart.
class _FakeLicenseRepository implements LicenseRepository {
  _FakeLicenseRepository(this.expiresAt);

  final DateTime expiresAt;
  int checkCalls = 0;

  LicenseStatus get _status => LicenseStatus(
        isVerified: true,
        expiresAt: expiresAt,
        planName: 'monthly',
        lastServerSync: DateTime.now(),
      );

  @override
  Future<Either<Failure, LicenseStatus>> checkLicense() async {
    checkCalls++;
    // Same server data every time — whether it's "active" is decided locally
    // by LicenseStatus.isExpired against the current clock, exactly as in
    // production (cached expiry keeps locking even offline).
    return Right(_status);
  }

  @override
  Future<({String? name, String? phone})> cachedAgent() async =>
      (name: 'صاحب المحل', phone: '0999999999');

  @override
  Future<LicenseStatus> cachedStatus() async => _status;

  @override
  Future<String> deviceId() async => 'device-1';

  @override
  Future<Either<Failure, LicenseStatus>> activate(
          {required String name, required String phone}) async =>
      Right(_status);

  @override
  Future<Either<Failure, List<SubscriptionPlan>>> getPlans() async =>
      const Right([]);

  @override
  Future<Either<Failure, void>> requestPlan(
          {required String name,
          required String phone,
          required SubscriptionPlan plan,
          required String contactMethod}) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> updateAgent(
          {required String name, required String phone}) async =>
      const Right(null);

  @override
  Future<void> registerPushToken(String token) async {}

  @override
  Future<void> syncGoogleAccount(String email) async {}

  @override
  Future<String?> cachedGoogleAccountHint() async => null;

  @override
  Future<Either<Failure, void>> submitReview(
          {required int stars, String? comment}) async =>
      const Right(null);

  @override
  Future<bool> hasReviewed() async => false;
}

void main() {
  test('expiry timer re-checks and locks the gate when the period ends',
      () async {
    // Expires ~200ms from now: comfortably "active" at first check, expired
    // shortly after — the timer (zero buffer for the test) must notice alone.
    final repo =
        _FakeLicenseRepository(DateTime.now().add(const Duration(milliseconds: 200)));
    final bloc = LicenseBloc(
        repository: repo, expiryCheckBuffer: const Duration(milliseconds: 50));

    bloc.add(CheckLicenseEvent());
    await bloc.stream
        .firstWhere((s) => s.status == LicenseFlowStatus.active);
    expect(repo.checkCalls, 1);

    // No events dispatched from here on — the bloc must lock by itself.
    final locked = await bloc.stream
        .firstWhere((s) => s.status == LicenseFlowStatus.unlicensed)
        .timeout(const Duration(seconds: 5));
    expect(repo.checkCalls, greaterThanOrEqualTo(2));
    expect(locked.license.isExpired, isTrue);
    expect(locked.isActive, isFalse);
    // Registered stays true → the router gate sends this user to the *plans*
    // screen (re-subscribe), not the name/phone registration form.
    expect(locked.registered, isTrue);

    await bloc.close();
  });

  test('no timer churn once already expired (no re-check loop)', () async {
    final repo = _FakeLicenseRepository(
        DateTime.now().subtract(const Duration(days: 1)));
    final bloc = LicenseBloc(
        repository: repo, expiryCheckBuffer: const Duration(milliseconds: 50));

    bloc.add(CheckLicenseEvent());
    await bloc.stream
        .firstWhere((s) => s.status == LicenseFlowStatus.unlicensed);
    final callsAfterCheck = repo.checkCalls;

    // Give a would-be timer plenty of room to misfire.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(repo.checkCalls, callsAfterCheck,
        reason: 'an inactive license must not arm the expiry timer');

    await bloc.close();
  });
}
