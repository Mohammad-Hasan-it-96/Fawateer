import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/enrollment_outcome.dart';
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

  /// The locally cached sync credential, or null if this device has not enrolled.
  Future<SyncSession?> currentSession();

  /// Forget the local seat on this device (does not revoke it server-side).
  Future<void> leave();
}
