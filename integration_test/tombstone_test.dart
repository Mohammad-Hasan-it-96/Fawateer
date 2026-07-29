// Tombstones end-to-end (Plan 002, Phase 0).
//
// Belongs on a device rather than in a host fake because the thing under test
// is the SQL: nine tables' worth of `deleted_at = ''` predicates, spread across
// typed Drift queries, hand-written aggregates and correlated subqueries. A
// fake repository would assert that the fake filters correctly and prove
// nothing. The failure this guards against is the one that makes sync look
// untrustworthy — a deleted row that is still counted, or one that comes back.
//
// Run: flutter test integration_test/tombstone_test.dart -d <deviceId>
import 'dart:io';

import 'package:billing_app/core/database/app_database.dart';
import 'package:billing_app/core/sync/sync_clock.dart';
// `isNull` collides with drift's SQL builder; the matcher is the one meant
// here.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late File dbFile;
  late AppDatabase db;
  late SyncClock clock;

  setUp(() async {
    dbFile = File(
        '${Directory.systemTemp.path}/fawateer_tombstone_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    if (dbFile.existsSync()) dbFile.deleteSync();
    db = AppDatabase.forTesting(NativeDatabase(dbFile));
    clock = SyncClock(db.settingsDao);
    await clock.load('testnode00000001');
  });

  tearDown(() async {
    await db.close();
    if (dbFile.existsSync()) dbFile.deleteSync();
  });

  Future<void> seedProduct(String id, String barcode, {double qty = 10}) =>
      db.productsDao.createProduct(ProductsCompanion.insert(
        id: id,
        name: 'منتج $id',
        barcode: Value(barcode),
        price: 5000,
        cost: const Value(3000),
        quantity: Value(qty),
      ));

  group('products', () {
    test('a deleted product disappears from every read path', () async {
      await seedProduct('p1', 'BR-1');
      await seedProduct('p2', 'BR-2');

      await db.productsDao.softDeleteProduct('p1', await clock.stamp());

      expect((await db.productsDao.getAllProducts()).map((p) => p.id), ['p2']);
      expect(await db.productsDao.getById('p1'), isNull);
      expect(await db.productsDao.getByBarcode('BR-1'), isNull,
          reason: 'scanning a deleted product must not resurrect it');
      expect((await db.productsDao.watchAllProducts().first).length, 1);
    });

    test('the row is still physically there, stamped', () async {
      await seedProduct('p1', 'BR-1');
      final stamp = await clock.stamp();
      await db.productsDao.softDeleteProduct('p1', stamp);

      // This is the whole point: "absent here, present there" is ambiguous to a
      // merge — never-synced or deliberately deleted? The tombstone is what
      // makes the delete travel instead of the row coming back.
      final raw = await db
          .customSelect("SELECT deleted_at, updated_at, origin_device "
              "FROM products WHERE id = 'p1'")
          .getSingle();
      expect(raw.read<String>('deleted_at'), stamp.hlc);
      expect(raw.read<String>('updated_at'), stamp.hlc,
          reason: 'a delete must also win last-write-wins against older edits');
      expect(raw.read<String>('origin_device'), 'testnode00000001');
    });

    test('deleting twice does not restamp the original deletion', () async {
      await seedProduct('p1', 'BR-1');
      final first = await clock.stamp();
      await db.productsDao.softDeleteProduct('p1', first);
      final second = await clock.stamp();
      final marked = await db.productsDao.softDeleteProduct('p1', second);

      expect(marked, 0, reason: 'nothing left to delete');
      final raw = await db
          .customSelect("SELECT deleted_at FROM products WHERE id = 'p1'")
          .getSingle();
      expect(raw.read<String>('deleted_at'), first.hlc,
          reason: 'a repeat delete must not make the delete look newer');
    });

    test('the freed barcode can be reused immediately', () async {
      await seedProduct('p1', 'BR-1');
      await db.productsDao.softDeleteProduct('p1', await clock.stamp());
      await seedProduct('p3', 'BR-1');

      final found = await db.productsDao.getByBarcode('BR-1');
      expect(found?.id, 'p3');
    });

    test('deleted stock leaves the inventory aggregates', () async {
      await seedProduct('p1', 'BR-1', qty: 10); // 10 × cost 3000 = 30,000
      await seedProduct('p2', 'BR-2', qty: 2); //  2 × cost 3000 =  6,000
      expect(await db.dashboardDao.inventoryValue(), 36000);

      await db.productsDao.softDeleteProduct('p1', await clock.stamp());
      expect(await db.dashboardDao.inventoryValue(), 6000,
          reason: 'a deleted product is not stock the shop owns');
    });
  });

  group('ledger and cashbox', () {
    setUp(() async {
      await db.customersDao.upsertCustomer(CustomersCompanion.insert(
        id: 'c1',
        name: 'أبو أحمد',
        createdAt: 1000,
      ));
    });

    test('a deleted ledger entry leaves the derived balance', () async {
      await db.ledgerDao.insertEntry(LedgerEntriesCompanion.insert(
        id: 'l1',
        customerId: 'c1',
        entryType: 'charge',
        amount: 15000,
        createdAt: 1000,
      ));
      await db.ledgerDao.insertEntry(LedgerEntriesCompanion.insert(
        id: 'l2',
        customerId: 'c1',
        entryType: 'payment',
        amount: 5000,
        createdAt: 2000,
      ));
      expect(await db.ledgerDao.watchBalance('c1').first, 10000);

      await db.ledgerDao.softDeleteEntry('l2', await clock.stamp());

      expect(await db.ledgerDao.watchBalance('c1').first, 15000,
          reason: 'the balance is derived from live rows only');
      expect((await db.ledgerDao.getEntries('c1')).map((e) => e.id), ['l1']);
      expect(await db.dashboardDao.outstandingDebts(), 15000);
    });

    test('a customer with only deleted entries becomes deletable', () async {
      await db.ledgerDao.insertEntry(LedgerEntriesCompanion.insert(
        id: 'l1',
        customerId: 'c1',
        entryType: 'charge',
        amount: 15000,
        createdAt: 1000,
      ));
      expect(await db.customersDao.countEntries('c1'), 1);

      await db.ledgerDao.softDeleteEntry('l1', await clock.stamp());

      // The delete guard exists so history is never silently discarded. Once
      // the history itself is gone, the guard has nothing left to protect —
      // and the shopkeeper is looking at an empty statement.
      expect(await db.customersDao.countEntries('c1'), 0);
    });

    test('a customer still appears in the list with no live entries', () async {
      await db.ledgerDao.insertEntry(LedgerEntriesCompanion.insert(
        id: 'l1',
        customerId: 'c1',
        entryType: 'charge',
        amount: 15000,
        createdAt: 1000,
      ));
      await db.ledgerDao.softDeleteEntry('l1', await clock.stamp());

      // The tombstone filter sits in the LEFT JOIN's ON clause; in the WHERE it
      // would quietly turn the join inner and drop every customer who owes
      // nothing — which is most of them.
      final rows = await db.customersDao.watchCustomersWithBalance().first;
      expect(rows.length, 1);
      expect(rows.single.balance, 0);
      expect(rows.single.entryCount, 0);
    });

    test('a deleted customer disappears but their name is not reused', () async {
      await db.customersDao.softDeleteCustomer('c1', await clock.stamp());

      expect(await db.customersDao.getCustomer('c1'), isNull);
      expect(await db.customersDao.watchCustomer('c1').first, isNull);
      expect(await db.customersDao.getAllCustomers(), isEmpty);
      // A deleted name must be free again — the shop is not barred from
      // re-adding a customer it removed by mistake.
      expect(await db.customersDao.nameExists('أبو أحمد'), isFalse);
    });

    test('a deleted cash movement leaves the drawer balance', () async {
      await db.cashboxDao
          .insertTransaction(CashboxTransactionsCompanion.insert(
        id: 'cb1',
        type: 'cashSale',
        amount: 15000,
        occurredAt: 1000,
        createdAt: 1000,
      ));
      await db.cashboxDao
          .insertTransaction(CashboxTransactionsCompanion.insert(
        id: 'cb2',
        type: 'expense',
        amount: -5000,
        occurredAt: 2000,
        createdAt: 2000,
      ));
      expect(await db.cashboxDao.watchBalance().first, 10000);

      await db.cashboxDao.softDeleteTransaction('cb2', await clock.stamp());

      expect(await db.cashboxDao.watchBalance().first, 15000);
      expect(await db.dashboardDao.cashBalance(), 15000,
          reason: 'the dashboard and the cashbox must not disagree');
      expect((await db.cashboxDao.watchTransactions().first).length, 1);
    });
  });

  group('invoices', () {
    Future<void> sell() => db.salesDao.insertInvoiceWithItems(
          invoice: SalesInvoicesCompanion.insert(
            id: 'inv1',
            createdAt: 1000,
            totalAmount: 10000,
          ),
          items: [
            SalesItemsCompanion.insert(
              invoiceId: 'inv1',
              productId: 'p1',
              productName: 'منتج p1',
              price: 5000,
              quantity: 2,
              cost: const Value(3000),
              uuid: const Value('inv1-line-1'),
            ),
          ],
          cashReceipt: CashboxTransactionsCompanion.insert(
            id: 'cb1',
            type: 'cashSale',
            amount: 10000,
            occurredAt: 1000,
            createdAt: 1000,
            relatedId: const Value('inv1'),
          ),
        );

    setUp(() async => seedProduct('p1', 'BR-1'));

    test('deleting an invoice takes its lines and its cash with it', () async {
      await sell();
      expect(await db.dashboardDao.cashBalance(), 10000);
      expect((await db.salesDao.getItemsForInvoice('inv1')).length, 1);

      await db.salesDao.softDeleteInvoice('inv1', await clock.stamp());

      expect(await db.salesDao.getAllInvoices(), isEmpty);
      expect(await db.salesDao.getItemsForInvoice('inv1'), isEmpty,
          reason: 'a line must not outlive its invoice on the other device');
      expect(await db.dashboardDao.cashBalance(), 0,
          reason: 'the cash entry the sale posted is reversed');
    });

    test('the deleted sale leaves every revenue aggregate', () async {
      await sell();
      final before = await db.dashboardDao.periodTotals(0, 9999999);
      expect(before.count, 1);
      expect(before.revenue, 10000);

      await db.salesDao.softDeleteInvoice('inv1', await clock.stamp());

      final after = await db.dashboardDao.periodTotals(0, 9999999);
      expect(after.count, 0);
      expect(after.revenue, 0);
      expect(after.profit, 0);
      expect(
          await db.dashboardDao
              .topProducts(0, 9999999, orderByColumn: 'revenue'),
          isEmpty);
      expect(await db.dashboardDao.invoiceStamps(0, 9999999), isEmpty);
    });

    test('the audit centre agrees with the dashboard', () async {
      await sell();
      await db.salesDao.softDeleteInvoice('inv1', await clock.stamp());

      // These two compute profit with duplicated SQL by design; a filter added
      // to one and not the other is exactly how they would drift apart.
      final summary = await db.salesDao
          .watchAuditSummary(
              fromMs: 0, toMs: 9999999, payment: 'all', search: '')
          .first;
      expect(summary.count, 0);
      expect(summary.total, 0);

      final list = await db.salesDao
          .watchAuditInvoices(
            fromMs: 0,
            toMs: 9999999,
            payment: 'all',
            search: '',
            orderBySql: 'i.created_at DESC',
            limit: 30,
            offset: 0,
          )
          .first;
      expect(list, isEmpty);
    });
  });

  group('serialized units', () {
    setUp(() async {
      await db.productsDao.createProduct(ProductsCompanion.insert(
        id: 'p2',
        name: 'هاتف',
        barcode: const Value('BR-2'),
        price: 5000000,
        isSerialized: const Value(true),
      ));
    });

    Future<void> addUnit(String id, String serial) =>
        db.productUnitsDao.insertUnit(ProductUnitsCompanion.insert(
          id: id,
          productId: 'p2',
          serial: serial,
          createdAt: 1000,
        ));

    test('deleting a unit hides it and re-syncs the cached quantity', () async {
      await addUnit('u1', 'IMEI-1');
      await addUnit('u2', 'IMEI-2');
      expect((await db.productsDao.getById('p2'))!.quantity, 2);

      await db.productUnitsDao.softDeleteUnit('u1', await clock.stamp());

      expect(await db.productUnitsDao.getUnitById('u1'), isNull);
      expect(await db.productUnitsDao.getBySerial('IMEI-1'), isNull,
          reason: 'scanning a deleted serial must not select it');
      expect(await db.productUnitsDao.availableCount('p2'), 1);
      expect((await db.productsDao.getById('p2'))!.quantity, 1,
          reason: 'quantity is a cache of the live unit count');
    });

    test('the serial is re-enterable but the old row keeps it', () async {
      await addUnit('u1', 'IMEI-1');
      await db.productUnitsDao.softDeleteUnit('u1', await clock.stamp());

      await addUnit('u2', 'IMEI-1');
      expect((await db.productUnitsDao.getBySerial('IMEI-1'))!.id, 'u2');

      final old = await db
          .customSelect("SELECT serial FROM product_units WHERE id = 'u1'")
          .getSingle();
      expect(old.read<String>('serial'), 'IMEI-1',
          reason: 'the tombstoned row IS the warranty record');
    });
  });

  group('attribute definitions', () {
    test('a deleted field vanishes from the definitions stream', () async {
      await db.attributesDao.upsert(AttributeDefinitionsCompanion.insert(
        id: 'd1',
        label: 'اللون',
      ));
      expect(await db.attributesDao.count(), 1);

      await db.attributesDao.softDeleteById('d1', await clock.stamp());

      expect(await db.attributesDao.count(), 0);
      expect(await db.attributesDao.getAll(), isEmpty);
      expect(await db.attributesDao.watchAll().first, isEmpty);
    });
  });
}
