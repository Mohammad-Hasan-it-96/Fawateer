// Device integration test for correcting how a sale was paid (Plan 016 C-a).
//
// It belongs here for the same reason the delete test does: what has to be true
// is a property of the database *after* one transaction across three tables —
// that exactly one money record exists for the sale afterwards, that it carries
// the sale's own amount and date, and above all that the sale itself did not
// move. A fake repository would only prove a method was called.
//
// Run: flutter test integration_test/invoice_payment_change_test.dart -d <deviceId>
import 'package:billing_app/core/database/app_database.dart';
import 'package:billing_app/core/database/daos/sales_dao.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The sale's own timestamp. Every posted row must carry it, not "now".
  const saleAt = 1000;

  late AppDatabase db;
  late SalesDao dao;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = SalesDao(db);

    await db.customStatement(
        "INSERT INTO products (id,name,price,quantity) VALUES ('p1','عصير',1000,7)");
    await db.customStatement(
        "INSERT INTO customers (id,name,created_at) VALUES "
        "('c1','أحمد',1000),('c2','سميرة',1000)");
    await db.customStatement(
        "INSERT INTO sales_invoices (id,created_at,total_amount) "
        "VALUES ('inv1',$saleAt,2000)");
    await db.customStatement(
        "INSERT INTO sales_items (invoice_id,product_id,product_name,price,quantity) "
        "VALUES ('inv1','p1','عصير',1000,2)");
  });

  tearDown(() async => db.close());

  Future<int> count(String sql) async {
    final row =
        await db.customSelect('SELECT COUNT(*) AS c FROM $sql').getSingle();
    return row.read<int>('c');
  }

  Future<Map<String, Object?>?> single(String sql) async {
    final rows = await db.customSelect(sql).get();
    return rows.isEmpty ? null : rows.first.data;
  }

  /// The sale as a cash sale leaves it: money in the drawer, no debt.
  Future<void> asCash() => db.customStatement(
      "INSERT INTO cashbox_transactions (id,type,amount,related_id,occurred_at,created_at) "
      "VALUES ('cb1','cashSale',2000,'inv1',$saleAt,$saleAt)");

  /// The same sale on credit to [customerId].
  Future<void> asCredit(String customerId) => db.customStatement(
      "INSERT INTO ledger_entries (id,customer_id,invoice_id,entry_type,amount,created_at) "
      "VALUES ('le1','$customerId','inv1','charge',2000,$saleAt)");

  testWidgets('cash becomes credit: the drawer entry is replaced by a debt',
      (tester) async {
    await asCash();

    final result = await dao.setInvoicePayment(
        invoiceId: 'inv1', customerId: 'c1', newRowId: 'new1');

    expect(result, PaymentChangeResult.ok);
    expect(await count("cashbox_transactions WHERE related_id = 'inv1'"), 0);
    final charge = await single(
        "SELECT * FROM ledger_entries WHERE invoice_id = 'inv1'");
    expect(charge!['customer_id'], 'c1');
    expect(charge['entry_type'], 'charge');
    expect(charge['amount'], 2000.0);
  });

  testWidgets('credit becomes cash: the debt is replaced by a drawer entry',
      (tester) async {
    await asCredit('c1');

    final result = await dao.setInvoicePayment(
        invoiceId: 'inv1', customerId: null, newRowId: 'new1');

    expect(result, PaymentChangeResult.ok);
    expect(await count("ledger_entries WHERE invoice_id = 'inv1'"), 0);
    final cash = await single(
        "SELECT * FROM cashbox_transactions WHERE related_id = 'inv1'");
    expect(cash!['type'], 'cashSale');
    expect(cash['amount'], 2000.0);
  });

  testWidgets('the sale itself never moves', (tester) async {
    // This is the whole reason C-a exists instead of delete-and-re-enter: the
    // receipt the customer is holding must stay valid, down to the invoice
    // number.
    await asCash();

    await dao.setInvoicePayment(
        invoiceId: 'inv1', customerId: 'c1', newRowId: 'new1');

    final invoice =
        await single("SELECT * FROM sales_invoices WHERE id = 'inv1'");
    expect(invoice!['total_amount'], 2000.0);
    expect(invoice['created_at'], saleAt);
    expect(await count("sales_items WHERE invoice_id = 'inv1'"), 1);
    final stock =
        await single("SELECT quantity AS q FROM products WHERE id = 'p1'");
    expect(stock!['q'], 7.0); // untouched — no stock was moved either way
  });

  testWidgets('the correction is dated at the sale, not at today',
      (tester) async {
    // A mis-recorded payment is a correction of something that already
    // happened. Dating it now would leave the sale's own day short *and* make
    // today's cash report wrong.
    await asCredit('c1');

    await dao.setInvoicePayment(
        invoiceId: 'inv1', customerId: null, newRowId: 'new1');

    final cash = await single(
        "SELECT * FROM cashbox_transactions WHERE related_id = 'inv1'");
    expect(cash!['occurred_at'], saleAt);
    expect(cash['created_at'], saleAt);
  });

  testWidgets('moving a credit sale to another customer leaves one debt',
      (tester) async {
    await asCredit('c1');

    await dao.setInvoicePayment(
        invoiceId: 'inv1', customerId: 'c2', newRowId: 'new1');

    expect(await count("ledger_entries WHERE customer_id = 'c1'"), 0);
    expect(await count("ledger_entries WHERE customer_id = 'c2'"), 1);
    expect(await count("ledger_entries WHERE invoice_id = 'inv1'"), 1);
  });

  testWidgets('applying the same choice twice does not double-post',
      (tester) async {
    // The method re-derives rather than diffing, so a repeat has to be a no-op.
    // If it appended instead, a double tap would bill the customer twice.
    await asCash();

    await dao.setInvoicePayment(
        invoiceId: 'inv1', customerId: 'c1', newRowId: 'new1');
    await dao.setInvoicePayment(
        invoiceId: 'inv1', customerId: 'c1', newRowId: 'new2');

    expect(await count("ledger_entries WHERE invoice_id = 'inv1'"), 1);
    expect(await count("cashbox_transactions WHERE related_id = 'inv1'"), 0);
  });

  testWidgets("a customer's own repayment is not swept up", (tester) async {
    // Only the row this invoice posted may go. A payment the customer made is
    // a separate event with no invoice link, and must survive.
    await asCredit('c1');
    await db.customStatement(
        "INSERT INTO ledger_entries (id,customer_id,entry_type,amount,created_at) "
        "VALUES ('le2','c1','payment',500,2000)");

    await dao.setInvoicePayment(
        invoiceId: 'inv1', customerId: null, newRowId: 'new1');

    expect(await count("ledger_entries WHERE id = 'le2'"), 1);
    expect(await count("ledger_entries WHERE id = 'le1'"), 0);
  });

  testWidgets('an unknown customer is refused before anything is touched',
      (tester) async {
    // The check runs first on purpose: the write clears the old record before
    // posting the new one, so failing halfway would leave the sale with no
    // money record at all.
    await asCash();

    final result = await dao.setInvoicePayment(
        invoiceId: 'inv1', customerId: 'ghost', newRowId: 'new1');

    expect(result, PaymentChangeResult.customerMissing);
    expect(await count("cashbox_transactions WHERE related_id = 'inv1'"), 1);
    expect(await count("ledger_entries WHERE invoice_id = 'inv1'"), 0);
  });

  testWidgets('an unknown invoice writes nothing', (tester) async {
    final result = await dao.setInvoicePayment(
        invoiceId: 'ghost', customerId: 'c1', newRowId: 'new1');

    expect(result, PaymentChangeResult.invoiceMissing);
    expect(await count('ledger_entries'), 0);
    expect(await count('cashbox_transactions'), 0);
  });

  // Plain `test`, not `testWidgets`: this is the only case that opens a live
  // Drift stream, and `testWidgets` fails any test that still has a timer
  // pending at teardown — which a watch query legitimately does. There is no
  // widget tree here to justify paying that check.
  test('the audit list reports the new payment type and customer', () async {
    // The list derives cash-vs-credit from the ledger rather than storing it,
    // so the correction has to show up there with no extra write.
    await asCash();
    await dao.setInvoicePayment(
        invoiceId: 'inv1', customerId: 'c1', newRowId: 'new1');

    final rows = await dao
        .watchAuditInvoices(
          fromMs: 0,
          toMs: 9999999,
          payment: 'all',
          search: '',
          orderBySql: 'i.created_at DESC',
          limit: 10,
          offset: 0,
        )
        .first;

    expect(rows.single.isCredit, isTrue);
    expect(rows.single.customerName, 'أحمد');
    expect(rows.single.customerId, 'c1');
  });

  testWidgets('a corrected sale can still be deleted cleanly', (tester) async {
    // The two Plan 016 actions have to compose: after a cash→credit
    // correction, deleting must reverse the *new* debt, not the cash entry
    // that no longer exists.
    await asCash();
    await dao.setInvoicePayment(
        invoiceId: 'inv1', customerId: 'c1', newRowId: 'new1');

    await dao.deleteInvoice('inv1');

    expect(await count("sales_invoices WHERE id = 'inv1'"), 0);
    expect(await count('ledger_entries'), 0);
    expect(await count('cashbox_transactions'), 0);
    final stock = await db
        .customSelect('SELECT quantity AS q FROM products WHERE id = ?',
            variables: [Variable.withString('p1')])
        .getSingle();
    expect(stock.read<double>('q'), 9.0); // 7 + the 2 that went back
  });
}
