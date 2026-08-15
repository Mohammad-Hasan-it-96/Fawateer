import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/enrollment_outcome.dart';
import '../entities/join_token.dart';
import '../entities/sync_device.dart';
import '../entities/sync_device_registry.dart';
import '../entities/sync_session.dart';

/// Enrollment of this device into a sync business (ADR 0011). The two entry
/// points mirror the two roles: an owner promotes its licensed device into a
/// business; a member joins an existing one with a scanned join token. Both
/// persist the resulting [SyncSession] locally on success.
abstract class SyncEnrollmentRepository {
  /// Owner onboarding: promote this licensed device into a sync business and
  /// obtain its owner seat token (`POST /api/v1/sync/business`). Idempotent
  /// server-side — a re-call rotates the token. Fails with
  /// [SyncError.subscriptionRequired] if the device has no verified subscription.
  Future<Either<Failure, EnrollmentOutcome>> establishAsOwner({String? pushToken});

  /// Member join: redeem a single-use join token to obtain a member seat token
  /// (`POST /api/v1/sync/enroll`). Fails with [SyncError.allowanceExceeded] at
  /// the business's device cap, or [SyncError.invalidJoinToken] for a bad code.
  Future<Either<Failure, EnrollmentOutcome>> joinBusiness(
    String joinToken, {
    String? pushToken,
  });

  /// Mint a single-use invitation for another device
  /// (`POST /api/v1/sync/enroll/token`, OWNER role only). Fails with
  /// [SyncError.allowanceExceeded] when the business is already at its device
  /// cap — refused at mint rather than at redemption, so the owner finds out
  /// while looking at their own phone instead of at the other person's.
  Future<Either<Failure, JoinToken>> mintJoinToken();

  /// Every seat in this business, plus the allowance the server states now
  /// (`GET /api/v1/sync/devices`, OWNER role only). The device holding the list
  /// is flagged via [SyncDevice.isCurrent], matched on the seat uuid this device
  /// already knows.
  Future<Either<Failure, SyncDeviceRegistry>> listDevices();

  /// Revoke a seat (`DELETE /api/v1/sync/devices/{uuid}`, OWNER role only).
  ///
  /// **This does not repossess data** (2026-07-29 R2). The revoked phone keeps a
  /// complete local copy of the books; what stops is its syncing and — once its
  /// next licence check lands, bounded by the existing 7-day offline grace — its
  /// selling. Nothing in this architecture can remote-wipe it, and the UI must
  /// not imply otherwise.
  ///
  /// The owner's own seat is refused server-side, not merely hidden here.
  Future<Either<Failure, Unit>> revokeDevice(String seatUuid);

  /// Give a seat an owner-assigned name
  /// (`PATCH /api/v1/sync/devices/{uuid}`, OWNER role only).
  ///
  /// Keyed off the **seat uuid**, the same identifier `DELETE` takes — never the
  /// device id (pinned with evotech-core, 2026-08-11 #2). Passing null clears
  /// the name; the server stores NULL and the row falls back to its role.
  ///
  /// Names are **not unique** by design: two tills both called "الكاشير" is a
  /// choice the owner is allowed to make, and de-duplicating would mean
  /// refusing a name for a reason no shopkeeper would guess.
  Future<Either<Failure, Unit>> renameDevice(String seatUuid, String? name);

  /// The locally cached sync credential, or null if this device has not enrolled.
  Future<SyncSession?> currentSession();

  /// Forget the local seat on this device (does not revoke it server-side).
  Future<void> leave();
}
