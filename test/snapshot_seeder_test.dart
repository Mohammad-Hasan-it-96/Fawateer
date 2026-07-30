// Seeding a bootstrap snapshot before it becomes the live database
// (Plan 002, bootstrap).
//
// A real-SQLite test rather than a fake, because the whole mechanism *is* the
// database: `ATTACH`, `PRAGMA seed.user_version`, and writes into a file that is
// not the one we are connected to. There is nothing left to assert once those
// are stubbed out.
//
// It runs on the host — `NativeDatabase` works under plain `flutter test` on a
// machine with sqlite3 available — so it is not in `integration_test/`. What
// lives there is behaviour that needs *Android's* SQLite build specifically.
import 'dart:io';

import 'package:billing_app/core/database/app_database.dart';
import 'package:billing_app/features/sync/data/snapshot_seeder.dart';
import 'package:billing_app/features/sync/data/sync_state_store.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late File dbFile;
  late File snapshotFile;
  late AppDatabase db;
  late SnapshotSeeder seeder;

  setUp(() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    dbFile = File('${Directory.systemTemp.path}/fawateer_seed_$stamp.sqlite');
    snapshotFile =
        File('${Directory.systemTemp.path}/fawateer_seed_snap_$stamp.sqlite');
    for (final f in [dbFile, snapshotFile]) {
      if (f.existsSync()) f.deleteSync();
    }
    db = AppDatabase.forTesting(NativeDatabase(dbFile));
    // Force the schema to be created before anything attaches.
    await db.customSelect('SELECT 1').getSingle();
    seeder = SnapshotSeeder(db);
  });

  tearDown(() async {
    await db.close();
    for (final f in [dbFile, snapshotFile]) {
      if (f.existsSync()) f.deleteSync();
    }
  });

  /// Produce a snapshot the way the owner's device does.
  Future<void> snapshot() =>
      db.customStatement('VACUUM INTO ?', [snapshotFile.path]);

  Future<String?> valueIn(File file, String key) async {
    await db.customStatement('ATTACH DATABASE ? AS probe', [file.path]);
    try {
      final rows = await db
          .customSelect('SELECT value FROM probe.app_settings WHERE key = ?',
              variables: [Variable<String>(key)])
          .get();
      return rows.isEmpty ? null : rows.first.read<String>('value');
    } finally {
      await db.customStatement('DETACH DATABASE probe');
    }
  }

  test('the snapshot reports the schema version it was written at', () async {
    await snapshot();
    expect(await seeder.schemaVersionOf(snapshotFile.path), db.schemaVersion);
  });

  test('the joiner starting position is written into the incoming file',
      () async {
    // The owner's own position, which the joiner must NOT inherit.
    await db.settingsDao.setValue(SyncStateStore.kPullCursor, '900');
    await db.settingsDao.setValue(SyncStateStore.kPushWatermark, 'owner-hlc');
    await snapshot();

    await seeder.seed(snapshotFile.path, cursor: 42, watermark: 'seed-hlc');

    expect(await valueIn(snapshotFile, SyncStateStore.kPullCursor), '42');
    expect(await valueIn(snapshotFile, SyncStateStore.kPushWatermark),
        'seed-hlc');
    // Our own database is untouched — it is about to be discarded, but writing
    // to it instead of the snapshot is the exact bug this class exists to avoid.
    expect(await valueIn(dbFile, SyncStateStore.kPullCursor), '900');
  });

  test("the owner's Drive rows do not travel with the shop", () async {
    await db.settingsDao.setValue('backup_account_email', 'owner@example.com');
    await db.settingsDao.setValue('backup_last_at', '2026-07-30T10:00:00.000');
    await db.settingsDao.setValue(SyncStateStore.kLastSyncAt, '1700000000000');
    // The printer deliberately stays: one shop, one thermal printer, and
    // arriving pre-paired is help rather than a false claim.
    await db.settingsDao.setValue('printer_mac', 'AA:BB:CC:DD:EE:FF');
    await snapshot();

    await seeder.seed(snapshotFile.path, cursor: 1, watermark: 'x');

    expect(await valueIn(snapshotFile, 'backup_account_email'), isNull);
    expect(await valueIn(snapshotFile, 'backup_last_at'), isNull);
    expect(await valueIn(snapshotFile, SyncStateStore.kLastSyncAt), isNull);
    expect(await valueIn(snapshotFile, 'printer_mac'), 'AA:BB:CC:DD:EE:FF');
  });

  test('the clock position survives, so new stamps sort above the snapshot',
      () async {
    // SyncClock.load() adopts our own node id but keeps the stored position.
    // Clearing it here would let this device author stamps below rows the
    // snapshot already holds, and last-write-wins would drop its first edits.
    await db.settingsDao.setValue('sync_hlc', '000001700000000-00003-ownerdev');
    await snapshot();

    await seeder.seed(snapshotFile.path, cursor: 1, watermark: 'x');

    expect(await valueIn(snapshotFile, 'sync_hlc'),
        '000001700000000-00003-ownerdev');
  });

  test('the highest stamp is read across every replicated table', () async {
    await snapshot();
    // Empty shop: nothing has been stamped, so there is nothing to decline to
    // push. The empty string is the same "predates sync" sentinel used
    // everywhere else, and collectSince skips it.
    expect(await seeder.highestHlcIn(snapshotFile.path, ['products']), '');
  });

  test('a failed body still detaches, so the next attempt is not poisoned',
      () async {
    await snapshot();
    // A leaked ATTACH would make every later call fail with "database seed is
    // already in use" — one bad download breaking every join until restart.
    await expectLater(
      seeder.highestHlcIn(snapshotFile.path, ['no_such_table']),
      throwsA(anything),
    );
    expect(await seeder.schemaVersionOf(snapshotFile.path), db.schemaVersion);
  });
}
