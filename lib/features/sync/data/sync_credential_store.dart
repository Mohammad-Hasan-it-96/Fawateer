import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/sync_seat_role.dart';
import '../domain/entities/sync_session.dart';

/// Local persistence for this device's sync credential (SharedPreferences),
/// mirroring `LicenseLocalStorage`. Kept out of the Drift database on purpose:
/// the seat token is device-local identity, not shop data, and — like the
/// licence — it must survive independently of the synced tables (a bootstrap
/// restore overwrites the whole SQLite file, and must not transplant one device's
/// seat onto another; ADR 0011, Decision 13).
class SyncCredentialStore {
  static const _kToken = 'sync_token';
  static const _kBusiness = 'sync_business_uuid';
  static const _kSeat = 'sync_seat_uuid';
  static const _kRole = 'sync_role';
  static const _kAllowance = 'sync_device_allowance';

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> save(SyncSession session) async {
    final p = await _p;
    await p.setString(_kToken, session.syncToken);
    await p.setString(_kBusiness, session.businessUuid);
    await p.setString(_kSeat, session.seatUuid);
    await p.setString(_kRole, session.role.name);
    await p.setInt(_kAllowance, session.deviceAllowance);
  }

  Future<SyncSession?> load() async {
    final p = await _p;
    final token = p.getString(_kToken);
    final business = p.getString(_kBusiness);
    final seat = p.getString(_kSeat);
    if (token == null || token.isEmpty || business == null || seat == null) {
      return null;
    }
    return SyncSession(
      syncToken: token,
      businessUuid: business,
      seatUuid: seat,
      role: SyncSeatRole.fromName(p.getString(_kRole)),
      deviceAllowance: p.getInt(_kAllowance) ?? 0,
    );
  }

  /// Forget the local seat (unenroll on this device). Does not revoke server-side
  /// — that is the owner's `DELETE /devices/{seat}`; this only clears the cache.
  Future<void> clear() async {
    final p = await _p;
    await p.remove(_kToken);
    await p.remove(_kBusiness);
    await p.remove(_kSeat);
    await p.remove(_kRole);
    await p.remove(_kAllowance);
  }
}
