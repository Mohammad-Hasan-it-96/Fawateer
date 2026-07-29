// Device integration test for the v13 → v14 migration (Plan 011 #10 —
// `sales_items.sale_type`). Runs against the bundled sqlite3_flutter_libs
// SQLite on a real device, because the one failure mode that matters here is
// *upgrade-time*: a shop with real sales data opens the new build and the
// migration either adds the column cleanly or bricks their database. Host unit
// tests use fakes and can never cover that.
//
// Run: flutter test integration_test/migration_v14_test.dart -d <deviceId>
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
        '${Directory.systemTemp.path}/fawateer_migration_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    if (dbFile.existsSync()) dbFile.deleteSync();
  });

  tearDown(() {
    if (dbFile.existsSync()) dbFile.deleteSync();
  });

  test('v13 → v14 adds sale_type and preserves existing sales data', () async {
    // ── 1. Build a "v13" database: full current schema, then drop the new
    // column and stamp the old user_version so opening it triggers onUpgrade.
    var db = AppDatabase.forTesting(NativeDatabase(dbFile));
    await db.customStatement(
        "INSERT INTO sales_invoices (id,created_at,total_amount) "
        "VALUES ('inv1',1000,5000)");
    // Two lines that bracket the interesting case: a whole-quantity weighed
    // sale (the one the old heuristic mislabels) and a normal piece sale.
    await db.customStatement(
        "INSERT INTO sales_items (invoice_id,product_id,product_name,price,quantity) VALUES "
        "('inv1','p1','Rice',2000,2)," // legacy weighed 2.000 kg
        "('inv1','p2','Soap',1000,3)");
    // Strip downwards from the current version — v16, v15, then v14. Dropping
    // only v14 would leave later columns on a database claiming user_version 13,
    // and those steps would then try to add them again.
    await stripV16(db);
    await stripV15(db);
    await stripV14(db);
    await db.customStatement('PRAGMA user_version = 13');
    await db.close();

    // ── 2. Reopen: Drift sees version 13 and runs the v14 step.
    db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final rows = await db.customSelect(
        'SELECT product_name, quantity, sale_type FROM sales_items '
        'ORDER BY product_name').get();

    // The migration ran (querying sale_type at all would throw otherwise) …
    expect(rows.length, 2, reason: 'existing sales rows must survive');
    // … and pre-existing rows decode as '' (unknown), NOT 'piece'. Defaulting
    // to 'piece' would have confidently mislabelled every old weighed sale;
    // '' is what makes the entity fall back to the quantity heuristic.
    for (final r in rows) {
      expect(r.read<String>('sale_type'), '',
          reason: 'legacy rows must read as unknown, not a piece claim');
    }
    expect(rows.first.read<String>('product_name'), 'Rice');
    expect(rows.first.read<double>('quantity'), 2.0);

    // ── 3. The upgraded schema accepts a snapshotted value going forward.
    await db.customStatement(
        "INSERT INTO sales_items (invoice_id,product_id,product_name,price,quantity,sale_type) "
        "VALUES ('inv1','p3','Meat',9000,1,'weight')");
    final fresh = await db
        .customSelect("SELECT sale_type FROM sales_items WHERE product_id='p3'")
        .getSingle();
    expect(fresh.read<String>('sale_type'), 'weight');

    await db.close();
  });
}
