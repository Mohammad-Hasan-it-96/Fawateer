// Device integration test for deleting a sale (Plan 016 A).
//
// It belongs here for the reason this folder exists: the reversal is one SQL
// transaction across five tables, and what has to be true is a property of the
// database *after* it — that no row the sale created is left behind, and that
// nothing it never touched was taken with it. A fake repository would only
// prove that a method was called.
//
// Run: flutter test integration_test/invoice_delete_test.dart -d <deviceId>
import 'package:billing_app/core/database/app_database.dart';
import 'package:billing_app/core/database/daos/sales_dao.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SalesDao dao;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = SalesDao(db);

    await db.customStatement(
        "INSERT INTO products (id,name,price,quantity,is_serialized) VALUES "
        "('p1','عصير',1000,7,0),"
        "('p2','هاتف',500000,1,1)");
    await db.customStatement(
        "INSERT INTO customers (id,name,created_at) VALUES ('c1','أحمد',1000)");
  });

  tearDown(() async => db.close());

  Future<int> count(String sql, [List<Variable> vars = const []]) async {
    final row =
        await db.customSelect('SELECT COUNT(*) AS c FROM $sql', variables: vars)
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
  /// database: invoice, line, stock deducted, cash in the drawer.
  Future<void> seedCashSale() async {
    await db.customStatement(
        "INSERT INTO sales_invoices (id,created_at,total_amount) "
        "VALUES ('inv1',1000,2000)");
    await db.customStatement(
        "INSERT INTO sales_items (invoice_id,product_id,product_name,price,quantity) "
        "VALUES ('inv1','p1','عصير',1000,2)");
    await db.customStatement(
        "INSERT INTO cashbox_transactions (id,type,amount,related_id,occurred_at,created_at) "
        "VALUES ('cb1','cashSale',2000,'inv1',1000,1000)");
    await db.customStatement(
        "UPDATE products SET quantity = quantity - 2 WHERE id = 'p1'");
  }

  /// The same sale on credit: a ledger charge instead of a cash entry.
  Future<void> seedCreditSale() async {
    await db.customStatement(
        "INSERT INTO sales_invoices (id,created_at,total_amount) "
        "VALUES ('inv1',1000,2000)");
    await db.customStatement(
        "INSERT INTO sales_items (invoice_id,product_id,product_name,price,quantity) "
        "VALUES ('inv1','p1','عصير',1000,2)");
    await db.customStatement(
        "INSERT INTO ledger_entries (id,customer_id,invoice_id,entry_type,amount,created_at) "
        "VALUES ('le1','c1','inv1','charge',2000,1000)");
    await db.customStatement(
        "UPDATE products SET quantity = quantity - 2 WHERE id = 'p1'");
  }

  testWidgets('a deleted sale leaves no invoice and no line items',
      (tester) async {
    await seedCashSale();
    await dao.deleteInvoice('inv1');

    expect(await count("sales_invoices WHERE id = 'inv1'"), 0);
    expect(await count("sales_items WHERE invoice_id = 'inv1'"), 0);
  });

  testWidgets('the goods go back on the shelf', (tester) async {
    await seedCashSale();
    expect(await quantityOf('p1'), 5); // 7 - 2 at sale time

    await dao.deleteInvoice('inv1');

    expect(await quantityOf('p1'), 7);
  });

  testWidgets('the cash comes back out of the drawer', (tester) async {
    await seedCashSale();
    await dao.deleteInvoice('inv1');

    expect(await count("cashbox_transactions WHERE related_id = 'inv1'"), 0);
  });

  testWidgets("a credit sale's debt is reversed with it", (tester) async {
    // The bug this pins: without it the customer kept owing money for a sale
    // that no longer existed. The balance is derived from these rows, so the
    // error was permanent and invisible.
    await seedCreditSale();
    expect(await count("ledger_entries WHERE customer_id = 'c1'"), 1);

    await dao.deleteInvoice('inv1');

    expect(await count("ledger_entries WHERE customer_id = 'c1'"), 0);
  });

  testWidgets('a manual entry on the same customer is left alone',
      (tester) async {
    // Only the charge this invoice posted may go. A repayment the customer
    // made is a separate event and must survive.
    await seedCreditSale();
    await db.customStatement(
        "INSERT INTO ledger_entries (id,customer_id,entry_type,amount,created_at) "
        "VALUES ('le2','c1','payment',500,2000)");

    await dao.deleteInvoice('inv1');

    expect(await count("ledger_entries WHERE id = 'le2'"), 1);
    expect(await count("ledger_entries WHERE id = 'le1'"), 0);
  });

  testWidgets('another invoice is untouched', (tester) async {
    await seedCashSale();
    await db.customStatement(
        "INSERT INTO sales_invoices (id,created_at,total_amount) "
        "VALUES ('inv2',2000,1000)");
    await db.customStatement(
        "INSERT INTO sales_items (invoice_id,product_id,product_name,price,quantity) "
        "VALUES ('inv2','p1','عصير',1000,1)");
    await db.customStatement(
        "INSERT INTO cashbox_transactions (id,type,amount,related_id,occurred_at,created_at) "
        "VALUES ('cb2','cashSale',1000,'inv2',2000,2000)");

    await dao.deleteInvoice('inv1');

    expect(await count("sales_invoices WHERE id = 'inv2'"), 1);
    expect(await count("sales_items WHERE invoice_id = 'inv2'"), 1);
    expect(await count("cashbox_transactions WHERE id = 'cb2'"), 1);
  });

  testWidgets('a serialized unit is released and its SKU count rebuilt',
      (tester) async {
    await db.customStatement(
        "INSERT INTO product_units (id,product_id,serial,status,sold_invoice_id,sold_at,created_at) "
        "VALUES ('u1','p2','355','sold','inv1',1000,1000)");
    await db.customStatement(
        "INSERT INTO sales_invoices (id,created_at,total_amount) "
        "VALUES ('inv1',1000,500000)");
    await db.customStatement(
        "INSERT INTO sales_items (invoice_id,product_id,product_name,price,quantity,serial_snapshot) "
        "VALUES ('inv1','p2','هاتف',500000,1,'355')");
    await db.customStatement("UPDATE products SET quantity = 0 WHERE id = 'p2'");

    await dao.deleteInvoice('inv1');

    // Back in stock, and the SKU's cached count is rebuilt from the units —
    // not incremented by the line quantity as well, which would double it.
    expect(await count("product_units WHERE id = 'u1' AND status = 'inStock'"),
        1);
    expect(await quantityOf('p2'), 1);
  });
}
