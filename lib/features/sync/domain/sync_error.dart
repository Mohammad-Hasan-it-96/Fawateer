import '../../../core/error/failure.dart';

/// The typed sync failures the UI must tell apart, mapped from the server's
/// machine-readable error codes (ADR 0011) plus the transport outcomes.
///
/// Following the app's rule — a repository/BLoC stores a *typed* error, never a
/// pre-rendered English string; the page maps it to a localized ARB message.
enum SyncError {
  /// The device has no verified subscription to enable sync (owner onboarding).
  subscriptionRequired,

  /// The business is already at its device allowance — prompt to upgrade.
  allowanceExceeded,

  /// The enrollment code is invalid, already used, or expired.
  invalidJoinToken,

  /// The device could not produce a stable id (the shared fallback) — sync needs one.
  fallbackDeviceRejected,

  /// This device's seat was revoked by the owner. Terminal, not retryable: the
  /// server has nulled the credential, so every further call fails the same way.
  deviceRevoked,

  /// The action needs the owner seat and this device is not it. Normally
  /// unreachable — owner-only actions are hidden rather than shown and refused —
  /// so seeing it means the local role and the server's disagree.
  ownerOnly,

  /// The server was unreachable (offline/timeout) — retryable.
  offline,

  /// The server was reached but errored, or returned something unexpected.
  server;

  /// Map a server `error.code` onto a typed error; unknown codes fall to [server].
  static SyncError fromCode(String? code) {
    switch (code) {
      case 'SUBSCRIPTION_REQUIRED':
        return SyncError.subscriptionRequired;
      case 'ALLOWANCE_EXCEEDED':
        return SyncError.allowanceExceeded;
      case 'INVALID_JOIN_TOKEN':
        return SyncError.invalidJoinToken;
      case 'FALLBACK_DEVICE_REJECTED':
        return SyncError.fallbackDeviceRejected;
      case 'DEVICE_REVOKED':
        return SyncError.deviceRevoked;
      case 'OWNER_ONLY':
      case 'OWNER_SEAT_NOT_REVOCABLE':
        return SyncError.ownerOnly;
      default:
        return SyncError.server;
    }
  }
}

/// A [Failure] that carries a typed [SyncError], so the sync repositories keep
/// the `Either<Failure, T>` contract the rest of the app uses while still
/// surfacing the code the UI needs.
class SyncFailure extends Failure {
  final SyncError error;

  const SyncFailure(this.error, super.message);

  @override
  List<Object> get props => [error, message];
}
