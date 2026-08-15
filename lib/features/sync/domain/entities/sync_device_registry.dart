import 'package:equatable/equatable.dart';

import 'sync_device.dart';

/// What `GET /api/v1/sync/devices` came back with: the seats, and how many the
/// business is allowed.
///
/// A value object rather than a bare `List<SyncDevice>` for two reasons, both of
/// which are things the list alone cannot say:
///
///  - **"none loaded" and "loaded, and there are none" are different answers.**
///    An owner who is offline has no registry, and a screen that renders an
///    empty list as "0 phones are using this shop" is stating something false
///    about a shop that may have three. Holding the whole registry as nullable
///    makes the unknown case unrepresentable-by-accident.
///  - **The allowance the server reports now beats the one cached at
///    enrollment.** `device_allowance` lives on the business row and is what a
///    plan upgrade changes (2026-07-27); `SyncSession.deviceAllowance` is a
///    snapshot from the day this device enrolled. An owner who has just paid for
///    five seats must not be told they have three.
class SyncDeviceRegistry extends Equatable {
  final List<SyncDevice> devices;

  /// Seats this business may hold, as the **server** states it, or null when it
  /// did not say. Null is not zero: an unstated allowance must never gate
  /// anything, because "we don't know" and "you have no seats" would produce the
  /// same locked screen.
  final int? allowance;

  /// Seats in use as the **server** counts them (`meta.seats_used`), or null
  /// when it did not say.
  ///
  /// Preferred over `devices.length` because the server computes it exactly the
  /// way the enrollment check enforces it — active, non-revoked seats. Counting
  /// the rows ourselves would be a second definition of "used", and the one
  /// that disagreed would tell an owner they have a seat free while the next
  /// enroll is refused, or the reverse.
  final int? seatsUsed;

  const SyncDeviceRegistry({
    this.devices = const [],
    this.allowance,
    this.seatsUsed,
  });

  int get used => seatsUsed ?? devices.length;

  /// True only when the server told us a limit *and* the seats are gone.
  ///
  /// The client check exists to spare the owner a doomed round trip and a red
  /// error for something predictable — it is **not** the enforcement. The server
  /// still refuses at mint with `ALLOWANCE_EXCEEDED`, which is what handles the
  /// cases this cannot see: a stale list, a seat taken on another phone a moment
  /// ago, or an allowance we were never told.
  bool get isAtCap {
    final limit = allowance;
    return limit != null && limit > 0 && used >= limit;
  }

  /// Whether there is anything honest to say about "x of y used".
  bool get hasAllowance => (allowance ?? 0) > 0;

  factory SyncDeviceRegistry.fromJson(
    Map<String, dynamic> data, {
    Map<String, dynamic>? envelope,
    String? currentSeat,
  }) {
    // The list may be the envelope's `data` directly or nested under `devices`;
    // both shapes appear elsewhere on this platform and neither is pinned here.
    final raw = data['devices'] ?? envelope?['data'];
    final devices = raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map((e) => SyncDevice.fromJson(e, currentSeat: currentSeat))
            // A row with no uuid is a button that cannot work — every action on
            // this screen is keyed by it.
            .where((d) => d.uuid.isNotEmpty)
            // **Revoked seats come back in `data` and must not be shown.** They
            // are the shop's history, not phones using it. Left in, a revoke
            // would look like it silently failed: the owner removes a phone,
            // the row vanishes optimistically, and then the re-read puts it
            // straight back — which is indistinguishable from the button not
            // working, on the one screen where trusting the button matters.
            .where((d) => !d.revoked)
            .toList()
        : <SyncDevice>[];

    // **The allowance is looked for in three places, and the envelope is the
    // one that matters.** `GET /sync/devices` returns the seats as `data[]`
    // (pinned 2026-08-15), so `data` is a LIST and there is no map to read a
    // number out of — the allowance must sit beside it, in the envelope or in
    // `meta`. Reading only `data` would silently find nothing, and the screen
    // would fall back to `SyncSession.deviceAllowance`, the number cached on
    // enrollment day. For a shop whose plan has not changed that is the same
    // value, so the display would look perfectly correct while the
    // server-authoritative path — the whole reason the tiers merge was chosen
    // over a config lever — was never exercised at all.
    final meta = envelope?['meta'];
    final allowance = data['device_allowance'] ??
        data['allowance'] ??
        envelope?['device_allowance'] ??
        envelope?['allowance'] ??
        (meta is Map ? (meta['device_allowance'] ?? meta['allowance']) : null);
    final used = (meta is Map ? meta['seats_used'] : null) ??
        data['seats_used'] ??
        envelope?['seats_used'];

    return SyncDeviceRegistry(
      devices: devices,
      allowance: allowance is int ? allowance : int.tryParse('$allowance'),
      seatsUsed: used is int ? used : int.tryParse('$used'),
    );
  }

  /// **Editing the list drops the server's count**, unless a new one is given.
  ///
  /// The only caller is the optimistic removal after a revoke. Keeping
  /// `seatsUsed` there would leave the row gone but the count unchanged for the
  /// length of a round trip — "1 phone listed, 2 of 3 used" — which reads as the
  /// screen contradicting itself. Falling back to `devices.length` for that
  /// moment is the honest answer, and the re-read restores the server's.
  SyncDeviceRegistry copyWith({
    List<SyncDevice>? devices,
    int? allowance,
    int? seatsUsed,
  }) =>
      SyncDeviceRegistry(
        devices: devices ?? this.devices,
        allowance: allowance ?? this.allowance,
        seatsUsed: seatsUsed ?? (devices == null ? this.seatsUsed : null),
      );

  @override
  List<Object?> get props => [devices, allowance, seatsUsed];
}
