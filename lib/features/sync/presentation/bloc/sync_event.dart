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

/// Owner: re-read the device registry. Dispatched automatically after the seat
/// loads and after a revoke; also available as a retry, because the registry is
/// the one part of this screen that needs the network to say anything at all.
class LoadDevicesRequested extends SyncEvent {
  const LoadDevicesRequested();
}

/// Owner: revoke another device's seat.
///
/// Takes the seat uuid rather than the [SyncDevice] so the event cannot carry a
/// stale row: the list is re-read after every revoke, and a queued second event
/// holding an object from the previous list would name a seat that is already
/// gone.
class RevokeDeviceRequested extends SyncEvent {
  final String seatUuid;
  const RevokeDeviceRequested(this.seatUuid);

  @override
  List<Object?> get props => [seatUuid];
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
