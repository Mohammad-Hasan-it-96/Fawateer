// Device integration test for the v14 → v15 migration (Plan 012 — serialized
// units). Runs against the bundled sqlite3_flutter_libs SQLite on a real
// device, because the failure mode that matters is *upgrade-time*: a shop with
// real sales data opens the new build and the migration either adds cleanly or
// bricks their database. Host unit tests use fakes and can never cover that.
//
// Run: flutter test integration_test/migration_v15_test.dart -d <deviceId>
import 'dart:io';

import 'package:billing_app/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late File dbFile;

  setUp(() async {
    dbFile = File(
        '${Directory.systemTemp.path}/fawateer_migration15_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    if (dbFile.existsSync()) dbFile.deleteSync();
  });

  tearDown(() {
    if (dbFile.existsSync()) dbFile.deleteSync();
  });

  /// Build a "v14" database: the full current schema with the v15 additions
  /// stripped and the old user_version stamped, so reopening triggers onUpgrade.
  Future<void> seedV14() async {
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    await db.customStatement(
        "INSERT INTO products (id,name,barcode,price,quantity) "
        "VALUES ('p1','iPhone 15','BOX-1',5000000,2)");
    await db.customStatement(
        "INSERT INTO sales_invoices (id,created_at,total_amount) "
        "VALUES ('inv1',1000,5000000)");
    await db.customStatement(
        "INSERT INTO sales_items (invoice_id,product_id,product_name,price,quantity) "
        "VALUES ('inv1','p1','iPhone 15',5000000,1)");

    await db.customStatement('DROP TABLE product_units');
    await db.customStatement('ALTER TABLE products DROP COLUMN is_serialized');
    await db
        .customStatement('ALTER TABLE sales_items DROP COLUMN serial_snapshot');
    await db.customStatement('PRAGMA user_version = 14');
    await db.close();
  }

  test('v14 → v15 adds serialized units and preserves existing data', () async {
    await seedV14();

    // Reopen: Drift sees version 14 and runs the v15 step.
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    // Existing rows survive, and both new columns decode as "not serialized" /
    // "no serial" — the whole point of an additive migration is that a shop
    // that never opts in sees no change at all.
    final product = await db
        .customSelect("SELECT name, quantity, is_serialized FROM products")
        .getSingle();
    expect(product.read<String>('name'), 'iPhone 15');
    expect(product.read<double>('quantity'), 2.0);
    expect(product.read<int>('is_serialized'), 0,
        reason: 'no existing product may be silently serialized');

    final line = await db
        .customSelect('SELECT serial_snapshot FROM sales_items')
        .getSingle();
    expect(line.read<String>('serial_snapshot'), '',
        reason: 'historical sale lines carry no serial');

    // The new table exists and accepts a unit.
    await db.customStatement(
        "INSERT INTO product_units (id,product_id,serial,created_at) "
        "VALUES ('u1','p1','IMEI-1',1000)");
    final unit = await db
        .customSelect('SELECT status, sold_invoice_id FROM product_units')
        .getSingle();
    expect(unit.read<String>('status'), 'inStock',
        reason: 'a new unit defaults to on-the-shelf');
    expect(unit.read<String>('sold_invoice_id'), '');

    await db.close();
  });

  test('the serial index refuses a duplicate IMEI but allows blanks', () async {
    await seedV14();
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    await db.customStatement(
        "INSERT INTO product_units (id,product_id,serial,created_at) "
        "VALUES ('u1','p1','IMEI-1',1000)");

    // An IMEI identifies one handset on earth. Without this the shop could
    // enter it twice and sell the same phone to two customers.
    await expectLater(
      db.customStatement(
          "INSERT INTO product_units (id,product_id,serial,created_at) "
          "VALUES ('u2','p1','IMEI-1',1000)"),
      throwsA(anything),
    );

    // Blank serials stay allowed — a unit logged before its label was read is
    // legitimate, which is why the index is partial.
    await db.customStatement(
        "INSERT INTO product_units (id,product_id,serial,created_at) "
        "VALUES ('u3','p1','',1000)");
    await db.customStatement(
        "INSERT INTO product_units (id,product_id,serial,created_at) "
        "VALUES ('u4','p1','',1000)");

    final count = await db
        .customSelect('SELECT COUNT(*) AS c FROM product_units')
        .getSingle();
    expect(count.read<int>('c'), 3, reason: 'u1 + two blank-serial units');

    await db.close();
  });
}
