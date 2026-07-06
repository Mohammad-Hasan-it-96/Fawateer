import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/license_status.dart';
import '../entities/subscription_plan.dart';

/// Contract for subscription/license verification against the server, with a
/// local cache so the app keeps working offline within the grace window.
abstract class LicenseRepository {
  /// Verify the current device with the server ([check_device]) and refresh the
  /// local cache. When the server can't be reached, returns the cached status
  /// (with offline/tamper guards applied) as a `Right` so the app stays usable
  /// within grace — a `Left` is reserved for genuinely unexpected failures.
  Future<Either<Failure, LicenseStatus>> checkLicense();

  /// Register / (re-)request activation for this device ([create_device]) using
  /// the agent's name + phone. Also persists them for later requests.
  Future<Either<Failure, LicenseStatus>> activate({
    required String name,
    required String phone,
  });

  /// File an operator-driven purchase request for [plan] with a chosen
  /// [contactMethod] (whatsapp/telegram/…). Marked `pending` server-side; a
  /// human then activates the device.
  Future<Either<Failure, void>> requestPlan({
    required String name,
    required String phone,
    required SubscriptionPlan plan,
    required String contactMethod,
  });

  /// The subscription plan catalog ([getPlans]).
  Future<Either<Failure, List<SubscriptionPlan>>> getPlans();

  /// The last cached status read from local storage (no network), with offline
  /// guards applied. Used to gate the UI instantly at startup.
  Future<LicenseStatus> cachedStatus();

  /// The agent identity captured at first activation (name, phone), if any.
  Future<({String? name, String? phone})> cachedAgent();

  /// This device's stable identifier (the value sent to the server and that the
  /// user gives to support for operator-driven activation).
  Future<String> deviceId();

  /// Best-effort registration of this device's FCM push [token] with the server
  /// so it can send the live-unlock notification when the subscription changes.
  /// Never throws — push is an optional enhancement; a failure just means the
  /// user re-checks manually or on next launch.
  Future<void> registerPushToken(String token);
}
