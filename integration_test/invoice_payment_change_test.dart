// Device integration test for correcting how a sale was paid (Plan 016 C-a),
// on the sync branch.
//
// What has to be true is a property of the database after one transaction
// across three tables: exactly one **live** money record for the sale, carrying
// the sale's own amount and date — and above all, the sale itself unmoved.
//
// Retiring a record here means **tombstoning** it, not deleting it. A row that
// is physically gone reads as "absent here, present there" to a merge and comes
// back on the next pull, which would silently restore a cash entry the shop
// just corrected away, or charge a customer twice.
//
// Run: flutter test integration_test/invoice_payment_change_test.dart -d <id>
import 'package:billing_app/core/database/app_database.dart';
import 'package:billing_app/core/database/daos/sales_dao.dart';
import 'package:billing_app/core/sync/sync_clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The sale's own timestamp. Every posted row must carry it, not "now".
  const saleAt = 1000;

  late AppDatabase db;
  late SalesDao dao;
  late SyncClock clock;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = SalesDao(db);
    clock = SyncClock(db.settingsDao);
    await clock.load('testnode00000001');

    await db.customStatement(
        "INSERT INTO products (id,name,price,quantity) VALUES ('p1','عصير',1000,7)");
    await db.customStatement(
        "INSERT INTO customers (id,name,created_at,updated_at) VALUES "
        "('c1','أحمد',1000,'h1'),('c2','سميرة',1000,'h1')");
    await db.customStatement(
        "INSERT INTO sales_invoices (id,created_at,total_amount,updated_at) "
        "VALUES ('inv1',$saleAt,2000,'h1')");
    await db.customStatement(
        "INSERT INTO sales_items (invoice_id,uuid,product_id,product_name,price,quantity,updated_at) "
        "VALUES ('inv1','inv1-1','p1','عصير',1000,2,'h1')");
  });

  tearDown(() async => db.close());

  /// Rows still visible to the app — i.e. not tombstoned.
  Future<int> live(String sql) async {
    final row =
        await db.customSelect('SELECT COUNT(*) AS c FROM $sql').getSingle();
    return row.read<int>('c');
  }

  Future<Map<String, Object?>?> single(String sql) async {
    final rows = await db.customSelect(sql).get();
    return rows.isEmpty ? null : rows.first.data;
  }

  Future<void> asCash() => db.customStatement(
      "INSERT INTO cashbox_transactions (id,type,amount,related_id,occurred_at,created_at,updated_at) "
      "VALUES ('cb1','cashSale',2000,'inv1',$saleAt,$saleAt,'h1')");

  Future<void> asCredit(String customerId) => db.customStatement(
      "INSERT INTO ledger_entries (id,customer_id,invoice_id,entry_type,amount,created_at,updated_at) "
      "VALUES ('le1','$customerId','inv1','charge',2000,$saleAt,'h1')");

  testWidgets('cash becomes credit: the drawer entry is replaced by a debt',
      (tester) async {
    await asCash();

    final result = await dao.setInvoicePayment(
        invoiceId: 'inv1',
        customerId: 'c1',
        newRowId: 'new1',
        stamp: await clock.stamp());

    expect(result, PaymentChangeResult.ok);
    expect(
        await live(
            "cashbox_transactions WHERE related_id = 'inv1' AND deleted_at = ''"),
        0);
    final charge = await single(
        "SELECT * FROM ledger_entries WHERE invoice_id = 'inv1' AND deleted_at = ''");
    expect(charge!['customer_id'], 'c1');
    expect(charge['entry_type'], 'charge');
    expect(charge['amount'], 2000.0);
  });

  testWidgets('the retired record is tombstoned, not deleted', (tester) async {
    // Deleting it would let the other till hand it back on the next pull, and
    // the shop would find the cash it just corrected away sitting in the
    // drawer again.
    await asCash();

    await dao.setInvoicePayment(
        invoiceId: 'inv1',
        customerId: 'c1',
        newRowId: 'new1',
        stamp: await clock.stamp());

    expect(await live("cashbox_transactions WHERE id = 'cb1'"), 1);
    final row =
        await single("SELECT * FROM cashbox_transactions WHERE id = 'cb1'");
    expect(row!['deleted_at'], isNot(''));
  });

  testWidgets('credit becomes cash: the debt is replaced by a drawer entry',
      (tester) async {
    await asCredit('c1');

    final result = await dao.setInvoicePayment(
        invoiceId: 'inv1',
        customerId: null,
        newRowId: 'new1',
        stamp: await clock.stamp());

    expect(result, PaymentChangeResult.ok);
    expect(
        await live(
            "ledger_entries WHERE invoice_id = 'inv1' AND deleted_at = ''"),
        0);
    final cash = await single(
        "SELECT * FROM cashbox_transactions WHERE related_id = 'inv1' AND deleted_at = ''");
    expect(cash!['type'], 'cashSale');
    expect(cash['amount'], 2000.0);
  });

  testWidgets('the sale itself never moves', (tester) async {
    // The whole reason C-a exists instead of delete-and-re-enter: the receipt
    // the customer is holding must stay valid, down to the invoice number.
    await asCash();

    await dao.setInvoicePayment(
        invoiceId: 'inv1',
        customerId: 'c1',
        newRowId: 'new1',
        stamp: await clock.stamp());

    final invoice = await single(
        "SELECT * FROM sales_invoices WHERE id = 'inv1' AND deleted_at = ''");
    expect(invoice!['total_amount'], 2000.0);
    expect(invoice['created_at'], saleAt);
    expect(
        await live("sales_items WHERE invoice_id = 'inv1' AND deleted_at = ''"),
        1);
    final stock =
        await single("SELECT quantity AS q FROM products WHERE id = 'p1'");
    expect(stock!['q'], 7.0); // untouched — no stock moved either way
  });

  testWidgets('the correction is dated at the sale, not at today',
      (tester) async {
    // A mis-recorded payment corrects something that already happened. Dating
    // it now would leave the sale's own day short *and* make today's cash
    // report wrong.
    await asCredit('c1');

    await dao.setInvoicePayment(
        invoiceId: 'inv1',
        customerId: null,
        newRowId: 'new1',
        stamp: await clock.stamp());

    final cash = await single(
        "SELECT * FROM cashbox_transactions WHERE related_id = 'inv1' AND deleted_at = ''");
    expect(cash!['occurred_at'], saleAt);
    expect(cash['created_at'], saleAt);
  });

  testWidgets('the new row is stamped, so it actually replicates',
      (tester) async {
    // A row with no HLC sits below the push watermark forever: the other till
    // would keep showing the payment type this device just corrected.
    await asCash();

    await dao.setInvoicePayment(
        invoiceId: 'inv1',
        customerId: 'c1',
        newRowId: 'new1',
        stamp: await clock.stamp());

    final charge = await single("SELECT * FROM ledger_entries WHERE id = 'new1'");
    expect(charge!['updated_at'], isNot(''));
    expect(charge['origin_device'], 'testnode00000001');
  });

  testWidgets('moving a credit sale to another customer leaves one debt',
      (tester) async {
    await asCredit('c1');

    await dao.setInvoicePayment(
        invoiceId: 'inv1',
        customerId: 'c2',
        newRowId: 'new1',
        stamp: await clock.stamp());

    expect(
        await live("ledger_entries WHERE customer_id = 'c1' AND deleted_at = ''"),
        0);
    expect(
        await live("ledger_entries WHERE customer_id = 'c2' AND deleted_at = ''"),
        1);
    expect(
        await live(
            "ledger_entries WHERE invoice_id = 'inv1' AND deleted_at = ''"),
        1);
  });

  testWidgets('applying the same choice twice does not double-post',
      (tester) async {
    // The method re-derives rather than diffing, so a repeat must be a no-op.
    // If it appended instead, a double tap would bill the customer twice.
    await asCash();

    await dao.setInvoicePayment(
        invoiceId: 'inv1',
        customerId: 'c1',
        newRowId: 'new1',
        stamp: await clock.stamp());
    await dao.setInvoicePayment(
        invoiceId: 'inv1',
        customerId: 'c1',
        newRowId: 'new2',
        stamp: await clock.stamp());

    expect(
        await live(
            "ledger_entries WHERE invoice_id = 'inv1' AND deleted_at = ''"),
        1);
    expect(
        await live(
            "cashbox_transactions WHERE related_id = 'inv1' AND deleted_at = ''"),
        0);
  });

  testWidgets("a customer's own repayment is not swept up", (tester) async {
    // Only the row this invoice posted may go. A payment the customer made is
    // a separate event with no invoice link, and must survive.
    await asCredit('c1');
    await db.customStatement(
        "INSERT INTO ledger_entries (id,customer_id,entry_type,amount,created_at,updated_at) "
        "VALUES ('le2','c1','payment',500,2000,'h1')");

    await dao.setInvoicePayment(
        invoiceId: 'inv1',
        customerId: null,
        newRowId: 'new1',
        stamp: await clock.stamp());

    expect(await live("ledger_entries WHERE id = 'le2' AND deleted_at = ''"), 1);
    expect(await live("ledger_entries WHERE id = 'le1' AND deleted_at = ''"), 0);
  });

  testWidgets('an unknown customer is refused before anything is touched',
      (tester) async {
    // The check runs first on purpose: the write retires the old record before
    // posting the new one, so failing halfway would leave the sale with no
    // money record at all.
    await asCash();

    final result = await dao.setInvoicePayment(
        invoiceId: 'inv1',
        customerId: 'ghost',
        newRowId: 'new1',
        stamp: await clock.stamp());

    expect(result, PaymentChangeResult.customerMissing);
    expect(
        await live(
            "cashbox_transactions WHERE related_id = 'inv1' AND deleted_at = ''"),
        1);
    expect(
        await live(
            "ledger_entries WHERE invoice_id = 'inv1' AND deleted_at = ''"),
        0);
  });

  testWidgets('a tombstoned customer is refused too', (tester) async {
    // Under sync a customer is never physically removed, so "does this row
    // exist?" is not the same question as "is this customer still ours?".
    await asCash();
    await db.customStatement(
        "UPDATE customers SET deleted_at = 'h9' WHERE id = 'c2'");

    final result = await dao.setInvoicePayment(
        invoiceId: 'inv1',
        customerId: 'c2',
        newRowId: 'new1',
        stamp: await clock.stamp());

    expect(result, PaymentChangeResult.customerMissing);
  });

  testWidgets('an unknown invoice writes nothing', (tester) async {
    final result = await dao.setInvoicePayment(
        invoiceId: 'ghost',
        customerId: 'c1',
        newRowId: 'new1',
        stamp: await clock.stamp());

    expect(result, PaymentChangeResult.invoiceMissing);
    expect(await live('ledger_entries'), 0);
    expect(await live('cashbox_transactions'), 0);
  });

  // Plain `test`, not `testWidgets`: this is the only case that opens a live
  // Drift stream, and `testWidgets` fails any test with a timer still pending
  // at teardown — which a watch query legitimately has. There is no widget
  // tree here to justify paying that check.
  test('the audit list reports the new payment type and customer', () async {
    await asCash();
    await dao.setInvoicePayment(
        invoiceId: 'inv1',
        customerId: 'c1',
        newRowId: 'new1',
        stamp: await clock.stamp());

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
    // correction, deleting must retire the *new* debt, not the cash entry that
    // is already tombstoned.
    await asCash();
    await dao.setInvoicePayment(
        invoiceId: 'inv1',
        customerId: 'c1',
        newRowId: 'new1',
        stamp: await clock.stamp());

    await dao.softDeleteInvoice('inv1', await clock.stamp());

    expect(await live("sales_invoices WHERE id = 'inv1' AND deleted_at = ''"), 0);
    expect(await live("ledger_entries WHERE deleted_at = ''"), 0);
    expect(await live("cashbox_transactions WHERE deleted_at = ''"), 0);
  });
}
