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

  /// Update the stored agent name/phone (edited from Settings). Always persists
  /// locally first; then best-effort pushes to the server (`update_my_data`).
  /// Returns `Left` when the server sync failed — the local save still
  /// succeeded, so callers can tell the user "saved, but not synced".
  Future<Either<Failure, void>> updateAgent({
    required String name,
    required String phone,
  });

  /// This device's stable identifier (the value sent to the server and that the
  /// user gives to support for operator-driven activation).
  Future<String> deviceId();

  /// Best-effort registration of this device's FCM push [token] with the server
  /// so it can send the live-unlock notification when the subscription changes.
  /// Never throws — push is an optional enhancement; a failure just means the
  /// user re-checks manually or on next launch.
  Future<void> registerPushToken(String token);

  /// Best-effort record of the Google account now holding this device's Drive
  /// backups (`update_my_data`). Never throws — losing this costs the operator a
  /// support convenience, never the backup itself, so it must not be able to
  /// fail a sign-in.
  Future<void> syncGoogleAccount(String email);

  /// The **masked** backup account last echoed by `check_device`
  /// (e.g. `y••••n@gmail.com`), or null if the server knows of none.
  ///
  /// Masked by design: `check_device` is a public, unauthenticated endpoint, so
  /// it must never return a usable address. This is only ever a recognition cue
  /// for the user who owns the account — never treat it as an email.
  Future<String?> cachedGoogleAccountHint();
}
