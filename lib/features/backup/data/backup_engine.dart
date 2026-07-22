import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../licensing/data/services/device_identity_service.dart';
import '../domain/entities/backup_manifest.dart';

/// The provider-agnostic core of the backup feature: turns the live Drift
/// database into a consistent, self-contained snapshot file, and swaps a
/// snapshot back in on restore. Knows nothing about Google Drive.
class BackupEngine {
  final AppDatabase _db;
  final DeviceIdentityService _deviceIdentity;

  const BackupEngine(this._db, this._deviceIdentity);

  /// The app's current DB schema version — used by the restore downgrade guard.
  int get schemaVersion => _db.schemaVersion;

  /// Produce a transactionally-consistent single-file copy of the DB using
  /// `VACUUM INTO` (safe while the DB is open; no WAL sidecar handling), and the
  /// manifest describing it. The caller uploads the file then deletes it.
  Future<(File file, BackupManifest manifest)> createSnapshot() async {
    final tmp = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${tmp.path}${Platform.pathSeparator}fawateer-$stamp.sqlite';

    // Remove any stale file at the target — VACUUM INTO fails if it exists.
    final out = File(path);
    if (await out.exists()) await out.delete();

    // Bind the path as a parameter (SQLite allows it for VACUUM INTO).
    await _db.customStatement('VACUUM INTO ?', [path]);

    final bytes = await out.readAsBytes();
    final digest = sha256.convert(bytes).toString();

    final counts = await _recordCounts();
    final info = await PackageInfo.fromPlatform();
    final deviceId = await _deviceIdentity.getDeviceId();

    final manifest = BackupManifest(
      schemaVersion: _db.schemaVersion,
      appVersion: '${info.version}+${info.buildNumber}',
      createdAt: DateTime.now(),
      deviceId: deviceId,
      sha256: digest,
      summary: 'inv:${counts.$1} cust:${counts.$2} prod:${counts.$3}',
    );
    return (out, manifest);
  }

  /// (invoices, customers, products) counts for the manifest summary.
  Future<(int, int, int)> _recordCounts() async {
    Future<int> count(String table) async {
      final row =
          await _db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle();
      return row.read<int>('c');
    }

    // Wrapped defensively: a count failure must not block a backup.
    try {
      return (
        await count('sales_invoices'),
        await count('customers'),
        await count('products'),
      );
    } catch (_) {
      return (0, 0, 0);
    }
  }

  /// Overwrite the live DB with [snapshot]. Closes the live connection first, so
  /// **the app must be restarted afterwards**. Before overwriting, the current
  /// DB is copied to `<db>.pre-restore` and, if the swap throws, rolled back — a
  /// restore can never destroy the data already on the device.
  Future<void> restoreSnapshot(File snapshot) async {
    // Resolve the real on-disk path of the live DB *before* closing it. Asking
    // SQLite directly is robust against drift_flutter's storage-location choice.
    final livePath = await _liveDbPath();
    final live = File(livePath);
    final preRestore = File('$livePath.pre-restore');

    await _db.close();

    try {
      if (await live.exists()) {
        await live.copy(preRestore.path);
      }
      // Drop WAL/SHM sidecars so a stale journal can't be replayed over the new
      // file, then swap in the snapshot.
      for (final suffix in const ['', '-wal', '-shm']) {
        final f = File('$livePath$suffix');
        if (await f.exists()) await f.delete();
      }
      await snapshot.copy(livePath);
    } catch (e) {
      // Roll back to the pre-restore copy if we got far enough to touch it.
      if (await preRestore.exists()) {
        await preRestore.copy(livePath);
      }
      rethrow;
    }
  }

  Future<String> _liveDbPath() async {
    final rows = await _db.customSelect('PRAGMA database_list').get();
    for (final r in rows) {
      if (r.read<String>('name') == 'main') {
        return r.read<String>('file');
      }
    }
    // Fallback: first row's file.
    return rows.first.read<String>('file');
  }
}
