// Device integration test for deleting a sale (Plan 016 A) on the sync branch.
//
// It belongs here for the reason this folder exists: the reversal is one SQL
// transaction across six tables, and what has to be true is a property of the
// database *after* it — that nothing the sale created is still live, and that
// nothing it never touched went with it. A fake repository would only prove
// that a method was called.
//
// **Everything here is a tombstone, never a delete.** A physically removed row
// reads as "absent here, present there" to a merge and comes back from the
// other till on the next pull, so a deleted sale would resurrect itself. Each
// assertion therefore checks the row is *not live* (`deleted_at != ''`) rather
// than absent, and several check the row is still physically there.
//
// Run: flutter test integration_test/invoice_delete_test.dart -d <deviceId>
import 'package:billing_app/core/database/app_database.dart';
import 'package:billing_app/core/database/daos/sales_dao.dart';
import 'package:billing_app/core/sync/sync_clock.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SalesDao dao;
  late SyncClock clock;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = SalesDao(db);
    clock = SyncClock(db.settingsDao);
    await clock.load('testnode00000001');

    await db.customStatement(
        "INSERT INTO products (id,name,price,quantity,is_serialized) VALUES "
        "('p1','عصير',1000,7,0),"
        "('p2','هاتف',500000,1,1)");
    await db.customStatement(
        "INSERT INTO customers (id,name,created_at) VALUES ('c1','أحمد',1000)");
    // p1's opening stock, as the v18 backfill would have written it.
    await db.customStatement(
        "INSERT INTO stock_movements (id,product_id,delta,reason,occurred_at,created_at) "
        "VALUES ('open-p1','p1',7,'openingBalance',500,500)");
  });

  tearDown(() async => db.close());

  /// Rows still visible to the app — i.e. not tombstoned.
  Future<int> live(String sql, [List<Variable> vars = const []]) async {
    final row = await db
        .customSelect('SELECT COUNT(*) AS c FROM $sql', variables: vars)
        .getSingle();
    return row.read<int>('c');
  }

  Future<double> quantityOf(String id) async {
    final row = await db
        .customSelect('SELECT quantity AS q FROM products WHERE id = ?',
            variables: [Variable.withString(id)])
        .getSingle();
    return row.read<double>('q');
  }

  /// A cash sale of 2 × p1, exactly as `insertInvoiceWithItems` leaves the
  /// database: invoice, line, a negative stock movement, cash in the drawer.
  Future<void> seedCashSale() async {
    await db.customStatement(
        "INSERT INTO sales_invoices (id,created_at,total_amount,updated_at) "
        "VALUES ('inv1',1000,2000,'h1')");
    await db.customStatement(
        "INSERT INTO sales_items (invoice_id,uuid,product_id,product_name,price,quantity,updated_at) "
        "VALUES ('inv1','inv1-1','p1','عصير',1000,2,'h1')");
    await db.customStatement(
        "INSERT INTO stock_movements (id,product_id,delta,reason,related_id,occurred_at,created_at,updated_at) "
        "VALUES ('mv1','p1',-2,'sale','inv1',1000,1000,'h1')");
    await db.customStatement(
        "INSERT INTO cashbox_transactions (id,type,amount,related_id,occurred_at,created_at,updated_at) "
        "VALUES ('cb1','cashSale',2000,'inv1',1000,1000,'h1')");
    await db.customStatement(
        "UPDATE products SET quantity = 5 WHERE id = 'p1'");
  }

  /// The same sale on credit: a ledger charge instead of a cash entry.
  Future<void> seedCreditSale() async {
    await db.customStatement(
        "INSERT INTO sales_invoices (id,created_at,total_amount,updated_at) "
        "VALUES ('inv1',1000,2000,'h1')");
    await db.customStatement(
        "INSERT INTO sales_items (invoice_id,uuid,product_id,product_name,price,quantity,updated_at) "
        "VALUES ('inv1','inv1-1','p1','عصير',1000,2,'h1')");
    await db.customStatement(
        "INSERT INTO stock_movements (id,product_id,delta,reason,related_id,occurred_at,created_at,updated_at) "
        "VALUES ('mv1','p1',-2,'sale','inv1',1000,1000,'h1')");
    await db.customStatement(
        "INSERT INTO ledger_entries (id,customer_id,invoice_id,entry_type,amount,created_at,updated_at) "
        "VALUES ('le1','c1','inv1','charge',2000,1000,'h1')");
    await db.customStatement(
        "UPDATE products SET quantity = 5 WHERE id = 'p1'");
  }

  testWidgets('a deleted sale leaves no live invoice and no live line items',
      (tester) async {
    await seedCashSale();
    await dao.softDeleteInvoice('inv1', await clock.stamp());

    expect(await live("sales_invoices WHERE id = 'inv1' AND deleted_at = ''"), 0);
    expect(
        await live("sales_items WHERE invoice_id = 'inv1' AND deleted_at = ''"),
        0);
  });

  testWidgets('the rows are tombstoned, not removed', (tester) async {
    // The distinction is the whole feature under sync: a physically deleted row
    // is ambiguous to a merge and gets resurrected from the other till.
    await seedCashSale();
    await dao.softDeleteInvoice('inv1', await clock.stamp());

    expect(await live("sales_invoices WHERE id = 'inv1'"), 1);
    expect(await live("sales_items WHERE invoice_id = 'inv1'"), 1);
    expect(await live("cashbox_transactions WHERE related_id = 'inv1'"), 1);
  });

  testWidgets('the goods go back on the shelf', (tester) async {
    await seedCashSale();
    expect(await quantityOf('p1'), 5); // 7 - 2 at sale time

    await dao.softDeleteInvoice('inv1', await clock.stamp());

    // Rebuilt from the movement log, which no longer counts the sale.
    expect(await quantityOf('p1'), 7);
  });

  testWidgets('the cash comes back out of the drawer', (tester) async {
    await seedCashSale();
    await dao.softDeleteInvoice('inv1', await clock.stamp());

    expect(
        await live(
            "cashbox_transactions WHERE related_id = 'inv1' AND deleted_at = ''"),
        0);
  });

  testWidgets("a credit sale's debt is reversed with it", (tester) async {
    // The bug this pins: without it the customer kept owing money for a sale
    // that no longer existed. The balance is derived from these rows, so the
    // error was permanent and invisible.
    await seedCreditSale();
    expect(
        await live("ledger_entries WHERE customer_id = 'c1' AND deleted_at = ''"),
        1);

    await dao.softDeleteInvoice('inv1', await clock.stamp());

    expect(
        await live("ledger_entries WHERE customer_id = 'c1' AND deleted_at = ''"),
        0);
  });

  testWidgets('a manual entry on the same customer is left alone',
      (tester) async {
    // Only the charge this invoice posted may go. A repayment the customer
    // made is a separate event and must survive.
    await seedCreditSale();
    await db.customStatement(
        "INSERT INTO ledger_entries (id,customer_id,entry_type,amount,created_at,updated_at) "
        "VALUES ('le2','c1','payment',500,2000,'h1')");

    await dao.softDeleteInvoice('inv1', await clock.stamp());

    expect(await live("ledger_entries WHERE id = 'le2' AND deleted_at = ''"), 1);
    expect(await live("ledger_entries WHERE id = 'le1' AND deleted_at = ''"), 0);
  });

  testWidgets('another invoice is untouched', (tester) async {
    await seedCashSale();
    await db.customStatement(
        "INSERT INTO sales_invoices (id,created_at,total_amount,updated_at) "
        "VALUES ('inv2',2000,1000,'h1')");
    await db.customStatement(
        "INSERT INTO sales_items (invoice_id,uuid,product_id,product_name,price,quantity,updated_at) "
        "VALUES ('inv2','inv2-1','p1','عصير',1000,1,'h1')");
    await db.customStatement(
        "INSERT INTO cashbox_transactions (id,type,amount,related_id,occurred_at,created_at,updated_at) "
        "VALUES ('cb2','cashSale',1000,'inv2',2000,2000,'h1')");

    await dao.softDeleteInvoice('inv1', await clock.stamp());

    expect(await live("sales_invoices WHERE id = 'inv2' AND deleted_at = ''"), 1);
    expect(
        await live("sales_items WHERE invoice_id = 'inv2' AND deleted_at = ''"),
        1);
    expect(
        await live("cashbox_transactions WHERE id = 'cb2' AND deleted_at = ''"),
        1);
  });

  testWidgets('a serialized unit is released and its SKU count rebuilt',
      (tester) async {
    await db.customStatement(
        "INSERT INTO product_units (id,product_id,serial,status,sold_invoice_id,sold_at,created_at,updated_at) "
        "VALUES ('u1','p2','355','sold','inv1',1000,1000,'h1')");
    await db.customStatement(
        "INSERT INTO sales_invoices (id,created_at,total_amount,updated_at) "
        "VALUES ('inv1',1000,500000,'h1')");
    await db.customStatement(
        "INSERT INTO sales_items (invoice_id,uuid,product_id,product_name,price,quantity,serial_snapshot,updated_at) "
        "VALUES ('inv1','inv1-1','p2','هاتف',500000,1,'355','h1')");
    await db.customStatement("UPDATE products SET quantity = 0 WHERE id = 'p2'");

    await dao.softDeleteInvoice('inv1', await clock.stamp());

    // Back in stock, and the SKU's cached count rebuilt from the units — a
    // serialized SKU counts units, never stock movements, so the two rules
    // cannot double up.
    expect(
        await live(
            "product_units WHERE id = 'u1' AND status = 'inStock' AND deleted_at = ''"),
        1);
    expect(await quantityOf('p2'), 1);
  });

  testWidgets('the unit itself is not tombstoned — the handset still exists',
      (tester) async {
    await db.customStatement(
        "INSERT INTO product_units (id,product_id,serial,status,sold_invoice_id,sold_at,created_at,updated_at) "
        "VALUES ('u1','p2','355','sold','inv1',1000,1000,'h1')");
    await db.customStatement(
        "INSERT INTO sales_invoices (id,created_at,total_amount,updated_at) "
        "VALUES ('inv1',1000,500000,'h1')");

    await dao.softDeleteInvoice('inv1', await clock.stamp());

    expect(await live("product_units WHERE id = 'u1' AND deleted_at = ''"), 1);
  });
}
