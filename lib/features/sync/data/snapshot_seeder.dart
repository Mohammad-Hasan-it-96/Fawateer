import '../../../core/database/app_database.dart';
import 'sync_state_store.dart';

/// Reads and rewrites the `app_settings` of a snapshot file **before** it is
/// swapped in as the live database (Plan 002, bootstrap).
///
/// This exists because of an ordering trap. `SyncStateStore` keeps the pull
/// cursor and push watermark in `app_settings` — deliberately, since they
/// describe the *data* and a restore that replaces the database must replace
/// them too. But `BackupEngine.restoreSnapshot` closes the connection and the
/// app must then be killed, so there is no moment *after* the swap at which the
/// joining device can write anything at all. Writing before the swap is equally
/// useless: the file being written is the one about to be overwritten.
///
/// So the values are written **into the incoming file**, through `ATTACH`, while
/// our own connection is still open. The alternative — relying on the owner's
/// cursor row already being inside the snapshot, which by construction it is —
/// would be correct today and correct by accident: nothing in the bootstrap
/// contract says the snapshot must carry the same value the handoff reports, and
/// the handoff is the authoritative one.
///
/// It also scrubs the owner's device-local rows. `app_settings` is not synced
/// and never was; a snapshot carries the *owner's* copy of it, and inheriting a
/// Drive account this device cannot sign into, or a "last backed up 2 hours ago"
/// that refers to a different phone, is a lie the joiner has no way to question.
class SnapshotSeeder {
  final AppDatabase _db;

  const SnapshotSeeder(this._db);

  /// Keys that describe the *owner's* device rather than the shop, and so must
  /// not survive the handover.
  ///
  /// The printer is deliberately **not** on this list: a shop generally has one
  /// thermal printer, both phones will pair to it, and arriving pre-paired is
  /// help rather than a lie. The Drive rows are, because a signed-in account is
  /// something only that handset actually has.
  static const _scrubbed = [
    'backup_account_email',
    'backup_last_at',
    'backup_auto_enabled',
    SyncStateStore.kLastSyncAt,
  ];

  /// The Drift schema version the snapshot was written at.
  ///
  /// Drift stores it in SQLite's own `user_version`, so this needs no manifest
  /// alongside the file — which matters, because unlike a Drive backup this
  /// snapshot travels as bare bytes through a third party.
  Future<int> schemaVersionOf(String path) async {
    return _attached(path, () async {
      final row = await _db.customSelect('PRAGMA seed.user_version').getSingle();
      return row.read<int>('user_version');
    });
  }

  /// Write this device's starting sync position into the snapshot.
  ///
  /// [cursor] is the owner's own pull position captured before their VACUUM;
  /// everything at or below it is in the file by definition, and everything
  /// above it gets pulled. [watermark] is the highest HLC the file contains, so
  /// the joiner does not push the owner's entire history straight back to the
  /// server it came from.
  Future<void> seed(
    String path, {
    required int cursor,
    required String watermark,
  }) async {
    await _attached(path, () async {
      await _db.customStatement(
        'INSERT OR REPLACE INTO seed.app_settings (key, value) VALUES (?, ?)',
        [SyncStateStore.kPullCursor, cursor.toString()],
      );
      await _db.customStatement(
        'INSERT OR REPLACE INTO seed.app_settings (key, value) VALUES (?, ?)',
        [SyncStateStore.kPushWatermark, watermark],
      );
      for (final key in _scrubbed) {
        await _db.customStatement(
          'DELETE FROM seed.app_settings WHERE key = ?',
          [key],
        );
      }
      // `sync_hlc` is left alone on purpose. SyncClock.load() already keeps a
      // stored stamp's position but adopts *our* node id, precisely because a
      // restored database can carry another handset's clock — and keeping the
      // position is what stops this device issuing stamps that sort below rows
      // the snapshot already holds.
    });
  }

  /// The highest `updated_at` in the snapshot, across every replicated table.
  ///
  /// Read from the file rather than from our own database: what matters is what
  /// the *incoming* rows are stamped at, and our own database is about to cease
  /// to exist.
  Future<String> highestHlcIn(String path, List<String> tables) async {
    return _attached(path, () async {
      var highest = '';
      for (final table in tables) {
        final row = await _db
            .customSelect(
                "SELECT MAX(updated_at) AS hlc FROM seed.$table WHERE updated_at != ''")
            .getSingle();
        final value = row.read<String?>('hlc') ?? '';
        if (value.compareTo(highest) > 0) highest = value;
      }
      return highest;
    });
  }

  /// Run [body] with [path] attached as `seed`, detaching even on failure —
  /// a leaked attachment would make every later attempt fail with "database
  /// seed is already in use", turning one bad download into a permanently
  /// broken join until the app restarts.
  Future<T> _attached<T>(String path, Future<T> Function() body) async {
    await _db.customStatement('ATTACH DATABASE ? AS seed', [path]);
    try {
      return await body();
    } finally {
      try {
        await _db.customStatement('DETACH DATABASE seed');
      } catch (_) {/* nothing useful to do; keep the original failure */}
    }
  }
}
