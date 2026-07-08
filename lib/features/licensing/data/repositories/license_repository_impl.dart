import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/license_status.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/repositories/license_repository.dart';
import '../datasources/license_local_storage.dart';
import '../datasources/license_remote_datasource.dart';
import '../services/device_identity_service.dart';

class LicenseRepositoryImpl implements LicenseRepository {
  final LicenseRemoteDataSource _remote;
  final LicenseLocalStorage _local;
  final DeviceIdentityService _identity;

  const LicenseRepositoryImpl(this._remote, this._local, this._identity);

  @override
  Future<Either<Failure, LicenseStatus>> checkLicense() async {
    final now = DateTime.now();
    try {
      final deviceId = await _identity.getDeviceId();
      final json = await _remote.checkDevice(deviceId);
      // Server reachable: persist result (verified or not) and stamp the sync.
      final status = json == null ? LicenseStatus.empty : _statusFromJson(json);
      await _local.saveStatus(status);
      await _local.markSynced(now,
          serverTime: json == null ? null : _parseDate(json['server_time']));
      // Re-read so offline/tamper guards are consistently applied.
      return Right(await _local.loadStatus(DateTime.now()));
    } on ApiException catch (e) {
      // Only offline errors reach here (checkDevice swallows server rejections);
      // fall back to cached state within the grace window.
      if (e.isOffline) return Right(await _local.loadStatus(now));
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LicenseStatus>> activate({
    required String name,
    required String phone,
  }) async {
    final now = DateTime.now();
    try {
      await _local.saveAgent(name, phone);
      final deviceId = await _identity.getDeviceId();
      final json = await _remote.createDevice(
          deviceId: deviceId,
          name: name,
          phone: phone,
          fcmToken: await _local.loadPushToken());
      await _local.saveStatus(_statusFromJson(json));
      await _local.markSynced(now, serverTime: _parseDate(json['server_time']));
      return Right(await _local.loadStatus(DateTime.now()));
    } on ApiException catch (e) {
      return Left(
          e.isOffline ? NetworkFailure(e.message) : ServerFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> requestPlan({
    required String name,
    required String phone,
    required SubscriptionPlan plan,
    required String contactMethod,
  }) async {
    try {
      await _local.saveAgent(name, phone);
      final deviceId = await _identity.getDeviceId();
      await _remote.requestPlan(
        deviceId: deviceId,
        name: name,
        phone: phone,
        requestedPlan: plan.requestedPlanCode,
        contactMethod: contactMethod,
      );
      return const Right(null);
    } on ApiException catch (e) {
      return Left(
          e.isOffline ? NetworkFailure(e.message) : ServerFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SubscriptionPlan>>> getPlans() async {
    try {
      return Right(await _remote.getPlans());
    } on ApiException catch (e) {
      return Left(
          e.isOffline ? NetworkFailure(e.message) : ServerFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<LicenseStatus> cachedStatus() => _local.loadStatus(DateTime.now());

  @override
  Future<({String? name, String? phone})> cachedAgent() => _local.loadAgent();

  @override
  Future<Either<Failure, void>> updateAgent({
    required String name,
    required String phone,
  }) async {
    // Persist locally first so the edit is never lost, even if the server is
    // unreachable; then try to sync so the operator sees the new details.
    await _local.saveAgent(name, phone);
    try {
      final deviceId = await _identity.getDeviceId();
      await _remote.updateAgentData(deviceId: deviceId, name: name, phone: phone);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(
          e.isOffline ? NetworkFailure(e.message) : ServerFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<String> deviceId() => _identity.getDeviceId();

  @override
  Future<void> registerPushToken(String token) async {
    if (token.isEmpty) return;
    try {
      // Cache first so activation can attach it even if the update call fails.
      await _local.savePushToken(token);
      final deviceId = await _identity.getDeviceId();
      await _remote.updateFcmToken(deviceId: deviceId, fcmToken: token);
    } catch (_) {
      // Non-fatal: token stays cached and re-registers on next launch/rotation.
    }
  }

  // ── mapping helpers ────────────────────────────────────────────────────────

  LicenseStatus _statusFromJson(Map<String, dynamic> json) => LicenseStatus(
        isVerified: _toBool(json['is_verified']),
        isTrial: _toBool(json['is_trial']),
        planName: json['plan']?.toString(),
        expiresAt: _parseDate(json['expires_at']),
      );

  static bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  /// Parse an ISO-8601 string or epoch (ms/seconds) into a [DateTime]; null on
  /// anything unparseable so downstream expiry logic stays safe.
  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is num) {
      final ms = v > 1e12 ? v.toInt() : (v * 1000).toInt();
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return DateTime.tryParse(v.toString());
  }
}
