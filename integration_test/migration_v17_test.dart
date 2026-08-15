// Device integration test for the v16 → v17 migration (Plan 002, Phase 0 —
// tombstones). Runs against the bundled sqlite3_flutter_libs SQLite on a real
// device because the whole step *is* SQLite behaviour: v17 adds no columns, it
// rescopes two partial-UNIQUE indexes, and whether a partial index actually
// stops matching a tombstoned row is a property of the engine, not of Dart.
//
// Run: flutter test integration_test/migration_v17_test.dart -d <deviceId>
import 'dart:io';

import 'package:billing_app/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'schema_downgrade.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late File dbFile;

  setUp(() async {
    dbFile = File(
        '${Directory.systemTemp.path}/fawateer_migration17_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    if (dbFile.existsSync()) dbFile.deleteSync();
  });

  tearDown(() {
    if (dbFile.existsSync()) dbFile.deleteSync();
  });

  /// Build a "v16" database: the current schema with v17's index rescoping
  /// undone and the old user_version stamped, so reopening runs the real step.
  Future<void> seedV16() async {
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    await db.customStatement(
        "INSERT INTO products (id,name,barcode,price,quantity) "
        "VALUES ('p1','رز','BR-1',5000,10)");
    await db.customStatement(
        "INSERT INTO products (id,name,barcode,price,quantity,is_serialized) "
        "VALUES ('p2','هاتف','BR-2',5000000,1,1)");
    await db.customStatement(
        "INSERT INTO product_units (id,product_id,serial,created_at) "
        "VALUES ('u1','p2','IMEI-1',1000)");
    await stripV19(db);
    await stripV18(db);
    await stripV17(db);
    await db.customStatement('PRAGMA user_version = 16');
    await db.close();
  }

  test('a tombstoned product stops reserving its barcode', () async {
    await seedV16();
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    // Before v17 this was a one-way door: the deleted row still occupied the
    // barcode, so a shop that deleted a product could never re-add anything
    // scanning to the same code. Hard deletes hid it; tombstones surface it.
    //
    // Since v19 the barcode index is no longer UNIQUE, so the insert below can
    // no longer be refused by the engine. What this still pins is the READ
    // rule every screen depends on — a tombstoned row is not on the shelf.
    await db.customStatement(
        "UPDATE products SET deleted_at = '001785312000000-00000-abc' "
        "WHERE id = 'p1'");
    await db.customStatement(
        "INSERT INTO products (id,name,barcode,price,quantity) "
        "VALUES ('p3','رز جديد','BR-1',6000,20)");

    final live = await db
        .customSelect("SELECT id FROM products WHERE barcode = 'BR-1' "
            "AND deleted_at = ''")
        .get();
    expect(live.length, 1, reason: 'exactly one LIVE product holds the barcode');
    expect(live.single.read<String>('id'), 'p3');

    await db.close();
  });

  test('an upgrade from v16 ends with a barcode index that is NOT unique',
      () async {
    // This test used to assert the opposite: v17 narrowed a UNIQUE barcode
    // index, so two live products sharing a code were refused. v19 (Plan 015
    // Case A) removed that constraint deliberately — the same packet is sold
    // at two prices from two piles, and the shop needs both rows.
    //
    // What is worth testing here is not the feature (migration_v19_test owns
    // that, from v18) but the ORDER of the chain. An upgrade starting at v16
    // runs v17, which CREATES the unique index, and then v19, which drops and
    // recreates it plain. Get those two the wrong way round — or let v19 use
    // `CREATE INDEX IF NOT EXISTS` without the drop — and the shop ends up on
    // the unique index anyway, with every second price refused by a
    // constraint that reads like a bug in the form.
    await seedV16();
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    await db.customStatement(
        "INSERT INTO products (id,name,barcode,price,quantity) "
        "VALUES ('p9','رز سعر ثاني','BR-1',6000,20)");

    final live = await db
        .customSelect("SELECT id FROM products WHERE barcode = 'BR-1' "
            "AND deleted_at = ''")
        .get();
    expect(live.length, 2, reason: 'both piles are on the shelf');

    final index = await db
        .customSelect("SELECT sql FROM sqlite_master WHERE type = 'index' "
            "AND name = 'idx_products_barcode'")
        .getSingle();
    expect(index.read<String>('sql').toUpperCase().contains('UNIQUE'), isFalse);

    await db.close();
  });

  test('a tombstoned unit frees its serial but keeps it on the row', () async {
    await seedV16();
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    await db.customStatement(
        "UPDATE product_units SET deleted_at = '001785312000000-00000-abc' "
        "WHERE id = 'u1'");
    // A handset re-entered after a mistaken delete must not be refused.
    await db.customStatement(
        "INSERT INTO product_units (id,product_id,serial,created_at) "
        "VALUES ('u2','p2','IMEI-1',2000)");

    // The tombstoned row keeps the serial — that row IS the warranty record,
    // and blanking it to free the index would destroy the only link back to
    // which handset it was.
    final old = await db
        .customSelect("SELECT serial FROM product_units WHERE id = 'u1'")
        .getSingle();
    expect(old.read<String>('serial'), 'IMEI-1');

    await db.close();
  });

  test('two live units still cannot share a serial', () async {
    await seedV16();
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    await expectLater(
      db.customStatement(
          "INSERT INTO product_units (id,product_id,serial,created_at) "
          "VALUES ('u3','p2','IMEI-1',2000)"),
      throwsA(anything),
    );

    await db.close();
  });

  test('existing data is untouched — v17 moves no rows', () async {
    await seedV16();
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    final rows = await db
        .customSelect('SELECT id, name, barcode, deleted_at FROM products '
            'ORDER BY id')
        .get();
    expect(rows.length, 2);
    expect(rows.first.read<String>('name'), 'رز');
    expect(rows.first.read<String>('barcode'), 'BR-1');
    for (final r in rows) {
      expect(r.read<String>('deleted_at'), '',
          reason: 'an index migration must never mark anything deleted');
    }

    await db.close();
  });
}
