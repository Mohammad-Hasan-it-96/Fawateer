part of 'sync_bloc.dart';

sealed class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

/// Read the cached seat and last-sync position. Dispatched by the page, not by
/// the route — matching `BackupPage`, whose route dispatches nothing.
class LoadSyncStatus extends SyncEvent {
  const LoadSyncStatus();
}

/// Promote this licensed device into a sync business (owner onboarding).
class EnableSyncAsOwner extends SyncEvent {
  const EnableSyncAsOwner();
}

/// Redeem a scanned or typed invitation.
class JoinWithToken extends SyncEvent {
  final String token;
  const JoinWithToken(this.token);

  @override
  List<Object?> get props => [token];
}

/// Owner: mint a single-use code for another device.
class MintJoinTokenRequested extends SyncEvent {
  const MintJoinTokenRequested();
}

/// Explicit user-initiated pass ("Sync now").
class SyncNowRequested extends SyncEvent {
  const SyncNowRequested();
}

/// Forget this device's seat locally. Does **not** revoke it server-side —
/// that is the owner's action from the device registry, and conflating the two
/// would let a member silently free a seat the owner is paying for.
class LeaveSyncRequested extends SyncEvent {
  const LeaveSyncRequested();
}

/// Acknowledge a one-shot message/error so it is not shown twice.
class ClearSyncFeedback extends SyncEvent {
  const ClearSyncFeedback();
}

/// Hide a displayed join code. Nothing caches it — a code still on screen after
/// it was redeemed is a code the owner will try to use again.
class DismissJoinToken extends SyncEvent {
  const DismissJoinToken();
}
