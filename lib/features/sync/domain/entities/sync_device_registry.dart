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

  const SyncDeviceRegistry({this.devices = const [], this.allowance});

  int get used => devices.length;

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
            .where((d) => d.uuid.isNotEmpty)
            .toList()
        : <SyncDevice>[];

    final allowance = data['device_allowance'] ?? data['allowance'];
    return SyncDeviceRegistry(
      devices: devices,
      allowance: allowance is int ? allowance : int.tryParse('$allowance'),
    );
  }

  SyncDeviceRegistry copyWith({List<SyncDevice>? devices, int? allowance}) =>
      SyncDeviceRegistry(
        devices: devices ?? this.devices,
        allowance: allowance ?? this.allowance,
      );

  @override
  List<Object?> get props => [devices, allowance];
}
