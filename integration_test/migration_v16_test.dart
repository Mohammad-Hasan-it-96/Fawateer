// Device integration test for the v15 → v16 migration (Plan 002, Phase 0 —
// multi-device sync groundwork). Runs against the bundled sqlite3_flutter_libs
// SQLite on a real device, because the failure mode that matters is
// *upgrade-time*: a shop with real sales data opens the new build and the
// migration either adds cleanly or bricks their database.
//
// This one earns the device test more than most. It touches NINE tables in a
// single step and backfills historical rows — the widest migration in the app's
// history — and it lands on an install that is already in production use.
//
// Run: flutter test integration_test/migration_v16_test.dart -d <deviceId>
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
        '${Directory.systemTemp.path}/fawateer_migration16_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    if (dbFile.existsSync()) dbFile.deleteSync();
  });

  tearDown(() {
    if (dbFile.existsSync()) dbFile.deleteSync();
  });

  /// Build a "v15" database: the current schema with every v16 addition
  /// stripped and the old user_version stamped, so reopening triggers onUpgrade.
  ///
  /// Seeded to look like a shop that has actually been trading — a product, a
  /// customer, an invoice with two lines, a debt entry and a cash movement —
  /// because a migration that only works on an empty database proves nothing.
  Future<void> seedV15() async {
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    await db.customStatement(
        "INSERT INTO products (id,name,barcode,price,quantity) "
        "VALUES ('p1','رز','BR-1',5000,10)");
    await db.customStatement(
        "INSERT INTO customers (id,name,created_at) VALUES ('c1','أبو أحمد',1000)");
    await db.customStatement(
        "INSERT INTO sales_invoices (id,created_at,total_amount) "
        "VALUES ('inv1',1000,15000)");
    // Two lines on one invoice, so the uuid backfill has to disambiguate rows
    // that share an invoice — the case a naive backfill would collide on.
    await db.customStatement(
        "INSERT INTO sales_items (invoice_id,product_id,product_name,price,quantity) "
        "VALUES ('inv1','p1','رز',5000,2)");
    await db.customStatement(
        "INSERT INTO sales_items (invoice_id,product_id,product_name,price,quantity) "
        "VALUES ('inv1','p1','رز',5000,1)");
    await db.customStatement(
        "INSERT INTO ledger_entries (id,customer_id,entry_type,amount,created_at) "
        "VALUES ('l1','c1','charge',15000,1000)");
    await db.customStatement(
        "INSERT INTO cashbox_transactions (id,type,amount,occurred_at,created_at) "
        "VALUES ('cb1','cashSale',15000,1000,1000)");

    // Downwards from the current version: v17 first (it rescoped the unique
    // indexes to reference deleted_at, and SQLite refuses to drop a column any
    // index mentions), then v16.
    await stripV18(db);
    await stripV17(db);
    await stripV16(db);
    await db.customStatement('PRAGMA user_version = 15');
    await db.close();
  }

  test('v15 → v16 adds sync metadata to every replicated table', () async {
    await seedV15();
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    // Every synced table must carry all three columns. Checked by querying
    // rather than by inspecting the schema, so a column that exists but is
    // unreadable still fails.
    for (final table in kSyncedTables) {
      final row = await db
          .customSelect(
              'SELECT updated_at, deleted_at, origin_device FROM $table LIMIT 1')
          .get();
      expect(row, isNotNull, reason: '$table lost its sync columns');
    }

    await db.close();
  });

  test('existing rows survive and decode as "predates sync"', () async {
    await seedV15();
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    final product = await db
        .customSelect('SELECT name, quantity, updated_at, deleted_at, '
            'origin_device, created_at FROM products')
        .getSingle();
    expect(product.read<String>('name'), 'رز');
    expect(product.read<double>('quantity'), 10.0);

    // The three sync columns must read as absent, not as a fabricated value.
    // A legacy row claiming a real timestamp would win last-write-wins against
    // a genuine edit made later on another device.
    expect(product.read<String>('updated_at'), '');
    expect(product.read<String>('origin_device'), '');
    expect(product.read<String>('deleted_at'), '',
        reason: 'no historical row may come back marked deleted');

    // createdAt backfills to 0 rather than "now" — we do not know when these
    // were added, and claiming we do would scramble newest-first ordering.
    expect(product.read<int>('created_at'), 0);

    // The rest of the shop's history is intact.
    final invoice = await db
        .customSelect('SELECT total_amount FROM sales_invoices')
        .getSingle();
    expect(invoice.read<double>('total_amount'), 15000.0);
    final ledger =
        await db.customSelect('SELECT amount FROM ledger_entries').getSingle();
    expect(ledger.read<double>('amount'), 15000.0);
    final cash = await db
        .customSelect('SELECT amount FROM cashbox_transactions')
        .getSingle();
    expect(cash.read<double>('amount'), 15000.0);

    await db.close();
  });

  test('sale lines are backfilled with unique sync ids', () async {
    await seedV15();
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    final rows =
        await db.customSelect('SELECT id, invoice_id, uuid FROM sales_items').get();
    expect(rows.length, 2);

    final uuids = rows.map((r) => r.read<String>('uuid')).toList();
    expect(uuids.every((u) => u.isNotEmpty), isTrue,
        reason: 'every historical line needs a sync identity');
    // Both lines belong to inv1, so this is exactly the case where a backfill
    // keyed only on the invoice would produce duplicates.
    expect(uuids.toSet().length, 2, reason: 'ids must be unique within a sale');
    for (final r in rows) {
      expect(r.read<String>('uuid'),
          '${r.read<String>('invoice_id')}-${r.read<int>('id')}',
          reason: 'backfill must be deterministic, not random');
    }

    await db.close();
  });

  test('the sync-id index refuses a duplicate but tolerates blanks', () async {
    await seedV15();
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    final existing = await db
        .customSelect("SELECT uuid FROM sales_items LIMIT 1")
        .getSingle();

    // Two devices must never converge on one row for two different sale lines.
    await expectLater(
      db.customStatement(
          "INSERT INTO sales_items (invoice_id,product_id,product_name,price,quantity,uuid) "
          "VALUES ('inv1','p1','رز',5000,1,'${existing.read<String>('uuid')}')"),
      throwsA(anything),
    );

    // Blank stays legal — the index is partial for the same reason
    // idx_products_barcode is: a row written before the value is known must not
    // brick the insert. (Nothing writes a blank uuid today; this guards the
    // migration against a legacy row the backfill somehow missed.)
    await db.customStatement(
        "INSERT INTO sales_items (invoice_id,product_id,product_name,price,quantity,uuid) "
        "VALUES ('inv1','p1','رز',5000,1,'')");
    await db.customStatement(
        "INSERT INTO sales_items (invoice_id,product_id,product_name,price,quantity,uuid) "
        "VALUES ('inv1','p1','رز',5000,1,'')");

    await db.close();
  });

  test('the migration is idempotent across a second open', () async {
    await seedV15();

    // First open runs the migration.
    var db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final firstPass = await db
        .customSelect('SELECT uuid FROM sales_items ORDER BY id')
        .get();
    await db.close();

    // Reopening at the current version must not re-run it or disturb anything.
    db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final secondPass = await db
        .customSelect('SELECT uuid FROM sales_items ORDER BY id')
        .get();

    expect(secondPass.map((r) => r.read<String>('uuid')),
        firstPass.map((r) => r.read<String>('uuid')),
        reason: 'a second open must not re-mint sync ids');

    await db.close();
  });
}
