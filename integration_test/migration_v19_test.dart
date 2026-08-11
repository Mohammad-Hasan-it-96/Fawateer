// Device migration test for v18 → v19: the barcode index stops being UNIQUE
// (Plan 015 Case A — the same packet sold at two prices from two piles).
//
// The failure this guards against is the one that actually hurts: a shop's
// database refusing to open after an update, or opening and then silently
// refusing every second price with a constraint error that reads like a bug in
// the form. Neither can be reproduced against a fake — the constraint is a
// property of the real SQLite index.
//
// The fixture is built by stripping the CURRENT schema down (see
// schema_downgrade.dart) rather than by hand, so it cannot quietly drift into
// claiming an old user_version while carrying new structure.
//
// Run: flutter test integration_test/migration_v19_test.dart -d <deviceId>
import 'dart:io';

import 'package:billing_app/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'schema_downgrade.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late File dbFile;

  setUp(() {
    dbFile = File('${Directory.systemTemp.path}/'
        'fawateer_v19_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    if (dbFile.existsSync()) dbFile.deleteSync();
  });

  tearDown(() {
    if (dbFile.existsSync()) dbFile.deleteSync();
  });

  /// A "v18" database: current schema, v19's index swap undone, old
  /// user_version stamped — so reopening runs the real upgrade step.
  Future<void> seedV18() async {
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    await db.customStatement(
        "INSERT INTO products (id,name,barcode,price,quantity,cost) "
        "VALUES ('p1','دخان أحمر','CIG-1',5000,10,4000)");
    await db.customStatement(
        "INSERT INTO products (id,name,barcode,price,quantity) "
        "VALUES ('p2','عصير','JUICE-1',1000,7)");
    await stripV19(db);
    await db.customStatement('PRAGMA user_version = 18');
    await db.close();
  }

  test('the shop opens, and its products are all still there', () async {
    // The first thing that must be true of any migration: the till starts.
    await seedV18();
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    final rows =
        await db.customSelect('SELECT id, barcode, price, cost FROM products')
            .get();

    expect(rows.length, 2);
    final cig = rows.firstWhere((r) => r.read<String>('id') == 'p1');
    expect(cig.read<String>('barcode'), 'CIG-1');
    expect(cig.read<double>('price'), 5000);
    expect(cig.read<double>('cost'), 4000);
    await db.close();
  });

  test('a second product may now share a barcode', () async {
    // The feature itself. Before v19 this insert threw.
    await seedV18();
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    await db.customStatement(
        "INSERT INTO products (id,name,barcode,price,quantity,cost) "
        "VALUES ('p1b','دخان أحمر (سعر ثاني)','CIG-1',6000,4,4800)");

    final sharing = await db
        .customSelect("SELECT id FROM products WHERE barcode = 'CIG-1' "
            "AND deleted_at = ''")
        .get();
    expect(sharing.length, 2);
    await db.close();
  });

  test('the two rows keep separate stock and cost', () async {
    // The reason A1 was chosen over "two prices on one product": the shelf
    // holds two piles, so the counts must not be shared.
    await seedV18();
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    await db.customStatement(
        "INSERT INTO products (id,name,barcode,price,quantity,cost) "
        "VALUES ('p1b','دخان أحمر (سعر ثاني)','CIG-1',6000,4,4800)");

    final rows = await db
        .customSelect("SELECT id, quantity, cost FROM products "
            "WHERE barcode = 'CIG-1' ORDER BY rowid")
        .get();

    expect(rows.map((r) => r.read<double>('quantity')), [10.0, 4.0]);
    expect(rows.map((r) => r.read<double>('cost')), [4000.0, 4800.0]);
    await db.close();
  });

  test('the index is gone as a constraint but kept as an index', () async {
    // Dropping it outright would make every scan a table scan on a shop with
    // thousands of products. The lookup is the app's hottest query.
    await seedV18();
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    final rows = await db
        .customSelect("SELECT sql FROM sqlite_master WHERE type = 'index' "
            "AND name = 'idx_products_barcode'")
        .get();

    expect(rows.length, 1, reason: 'the index must still exist');
    expect(rows.single.read<String>('sql').toUpperCase().contains('UNIQUE'),
        isFalse);
    await db.close();
  });

  test('an existing duplicate is no longer blanked on upgrade', () async {
    // A legacy v1–v3 database could hold two products on one barcode, and
    // `_createIndexes` used to blank all but the earliest so the UNIQUE index
    // could be built. With a plain index nothing throws — and that statement
    // would now destroy exactly the data this feature exists to hold.
    await seedV18();
    // Insert the duplicate while the unique index is still absent, mimicking
    // the legacy shape the de-dup was written for.
    final seed = AppDatabase.forTesting(NativeDatabase(dbFile));
    await seed.customStatement('DROP INDEX IF EXISTS idx_products_barcode');
    await seed.customStatement(
        "INSERT INTO products (id,name,barcode,price,quantity) "
        "VALUES ('legacy','دخان قديم','CIG-1',4500,3)");
    await seed.customStatement('PRAGMA user_version = 18');
    await seed.close();

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final kept = await db
        .customSelect("SELECT id FROM products WHERE barcode = 'CIG-1'")
        .get();

    expect(kept.length, 2, reason: 'both keep their barcode');
    await db.close();
  });

  test('re-running the upgrade is harmless', () async {
    // Migrations get re-run in the field more often than anyone plans for —
    // a restore, a crash mid-upgrade, a reinstall over existing data.
    await seedV18();
    final first = AppDatabase.forTesting(NativeDatabase(dbFile));
    await first.customStatement(
        "INSERT INTO products (id,name,barcode,price,quantity) "
        "VALUES ('p1b','دخان ثاني','CIG-1',6000,4)");
    await first.close();

    final second = AppDatabase.forTesting(NativeDatabase(dbFile));
    final rows = await second
        .customSelect("SELECT id FROM products WHERE barcode = 'CIG-1'")
        .get();

    expect(rows.length, 2);
    await second.close();
  });
}
