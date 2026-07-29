import 'package:equatable/equatable.dart';

import 'sync_seat_role.dart';

/// This device's durable sync credential and identity within its business
/// (ADR 0011). Obtained once at enrollment (owner onboarding or member join) and
/// cached locally — the analogue of the licensing `LicenseStatus`, but for sync.
///
/// The [syncToken] is the Bearer credential for every guarded `/api/v1/sync/*`
/// call; it is durable across subscription expiry (an expired device must still
/// push stranded offline sales). [deviceAllowance] is how many devices the
/// business may hold — surfaced so the owner UI can show "2 of 3 devices used".
class SyncSession extends Equatable {
  /// The Bearer token for guarded sync calls. Shown by the server exactly once.
  final String syncToken;

  /// The business this device belongs to (the scope of all its sync data).
  final String businessUuid;

  /// This device's own seat.
  final String seatUuid;

  final SyncSeatRole role;

  /// How many devices the business may hold (owner-relevant).
  final int deviceAllowance;

  const SyncSession({
    required this.syncToken,
    required this.businessUuid,
    required this.seatUuid,
    required this.role,
    required this.deviceAllowance,
  });

  bool get isOwner => role.isOwner;

  SyncSession copyWith({String? syncToken, int? deviceAllowance}) {
    return SyncSession(
      syncToken: syncToken ?? this.syncToken,
      businessUuid: businessUuid,
      seatUuid: seatUuid,
      role: role,
      deviceAllowance: deviceAllowance ?? this.deviceAllowance,
    );
  }

  @override
  List<Object> get props => [syncToken, businessUuid, seatUuid, role, deviceAllowance];
}
