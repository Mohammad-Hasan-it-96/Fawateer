import 'package:equatable/equatable.dart';

import 'sync_seat_role.dart';

/// One seat in the business's device registry
/// (`GET /api/v1/sync/devices`, owner role only).
///
/// **Telling one row from another is the whole design problem here.** A shop
/// with three identical linked phones gets three identical rows, and revoking
/// the wrong one takes a working till off the counter mid-shift. Three things
/// distinguish them:
///
///  - [label] — the owner's own name for the phone, and much the best of the
///    three, because it is the only one carrying the shop's own meaning
///    ("الكاشير", "المحل الثاني"). There was no field for it in the first
///    contract; the server gained one on 2026-08-11, and the app now also
///    *proposes* the handset model at enrollment, so even a shop that never
///    renames anything sees rows it can tell apart.
///  - [isCurrent] — the phone in the owner's hand, matched on the seat uuid the
///    device already holds. It is never revocable (see below), so marking it is
///    also what stops the owner locking themselves out by accident.
///  - [lastSeenAt] — the fallback discriminator, and it stays visible even on a
///    named row: a name says WHICH phone this is, not whether it is still
///    working. "last seen two minutes ago" against "three days ago" is how an
///    owner identifies the tablet that left with a staff member.
class SyncDevice extends Equatable {
  /// The seat's uuid — what `DELETE /sync/devices/{uuid}` takes.
  final String uuid;

  final SyncSeatRole role;

  /// The owner-assigned name, or null when the seat is unnamed.
  ///
  /// **Null is a real state, not a missing value** — the server stores NULL for
  /// empty-after-trim, which is how a name is cleared. The UI must fall back to
  /// the role rather than inventing a placeholder, because a made-up name is
  /// indistinguishable from one the owner actually chose.
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
