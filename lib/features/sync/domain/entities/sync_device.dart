import 'package:equatable/equatable.dart';

import 'sync_seat_role.dart';

/// One seat in the business's device registry
/// (`GET /api/v1/sync/devices`, owner role only).
///
/// **Telling one row from another is the whole design problem here.** A shop
/// with three identical linked phones gets three identical rows, and revoking
/// the wrong one takes a working till off the counter mid-shift. Two things
/// distinguish them, and both matter:
///
///  - [isCurrent] — the phone in the owner's hand, matched on the seat uuid the
///    device already holds. It is never revocable (see below), so marking it is
///    also what stops the owner locking themselves out by accident.
///  - [lastSeenAt] — the only other discriminator available. "last seen two
///    minutes ago" against "last seen three days ago" is exactly how an owner
///    identifies the tablet that left with a staff member.
///
/// A user-assigned device name would beat both, but there is no field for one in
/// the negotiated contract; worth raising before this ships to a 5-seat shop.
class SyncDevice extends Equatable {
  /// The seat's uuid — what `DELETE /sync/devices/{uuid}` takes.
  final String uuid;

  final SyncSeatRole role;

  /// A server-supplied label, when there is one. Not in the pinned contract, so
  /// it is read opportunistically and the UI falls back to the role.
  final String? label;

  /// When the server last heard from this device, if it says.
  final DateTime? lastSeenAt;

  /// True for the seat held by the phone showing the list.
  final bool isCurrent;

  const SyncDevice({
    required this.uuid,
    required this.role,
    this.label,
    this.lastSeenAt,
    this.isCurrent = false,
  });

  /// **The owner seat is not revocable** — refused at the endpoint, not merely
  /// hidden here (2026-07-29 R1). Revoking it orphans the business: a live
  /// subscription with no device able to mint a join code, and no way back
  /// without operator intervention. The current device is excluded too, for the
  /// blunter reason that a phone revoking itself is never what was meant.
  bool get isRevocable => !role.isOwner && !isCurrent;

  factory SyncDevice.fromJson(Map<String, dynamic> json, {String? currentSeat}) {
    final uuid = json['uuid']?.toString() ?? json['seat_uuid']?.toString() ?? '';
    final seen = json['last_seen_at'];
    DateTime? lastSeen;
    if (seen is int) {
      lastSeen = DateTime.fromMillisecondsSinceEpoch(seen * 1000);
    } else if (seen != null) {
      lastSeen = DateTime.tryParse(seen.toString())?.toLocal();
    }
    final label = json['label'] ?? json['name'] ?? json['device_name'];
    return SyncDevice(
      uuid: uuid,
      role: SyncSeatRole.fromName(json['role']?.toString()),
      label: (label?.toString().isEmpty ?? true) ? null : label.toString(),
      lastSeenAt: lastSeen,
      isCurrent: uuid.isNotEmpty && uuid == currentSeat,
    );
  }

  @override
  List<Object?> get props => [uuid, role, label, lastSeenAt, isCurrent];
}
