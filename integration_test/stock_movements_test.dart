// The stock movement log end-to-end (Plan 002, Phase 0 — "inventory, the hard
// one"), plus the v17 → v18 migration that introduces it.
//
// On a device because the whole design lives in SQL: on-hand is a `SUM(delta)`
// with a floor, chosen per product by a `CASE` on `is_serialized`, recomputed
// inside transactions that also write invoices and units. A host fake would
// assert that the fake adds up.
//
// The failure this guards against is the one Plan 002 names outright: stock
// held as a scalar and merged last-write-wins loses a sale outright — two
// devices each selling one of five converge on "4".
//
// Run: flutter test integration_test/stock_movements_test.dart -d <deviceId>
import 'dart:io';

import 'package:billing_app/core/database/app_database.dart';
import 'package:billing_app/core/sync/sync_clock.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'schema_downgrade.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late File dbFile;
  late AppDatabase db;
  late SyncClock clock;

  setUp(() async {
    dbFile = File(
        '${Directory.systemTemp.path}/fawateer_stock_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    if (dbFile.existsSync()) dbFile.deleteSync();
    db = AppDatabase.forTesting(NativeDatabase(dbFile));
    clock = SyncClock(db.settingsDao);
    await clock.load('testnode00000001');
  });

  tearDown(() async {
    await db.close();
    if (dbFile.existsSync()) dbFile.deleteSync();
  });

  Future<void> addProduct(String id,
          {String barcode = '', bool serialized = false}) =>
      db.productsDao.createProduct(ProductsCompanion.insert(
        id: id,
        name: 'منتج $id',
        barcode: Value(barcode),
        price: 5000,
        cost: const Value(3000),
        isSerialized: Value(serialized),
      ));

  Future<void> move(String id, String productId, double delta,
      {String reason = 'adjustment', String relatedId = ''}) async {
    final stamp = await clock.stamp();
    await db.stockDao.recordMovement(StockMovementsCompanion.insert(
      id: id,
      productId: productId,
      delta: delta,
      reason: Value(reason),
      relatedId: Value(relatedId),
      occurredAt: 1000,
      createdAt: 1000,
      updatedAt: Value(stamp.hlc),
      originDevice: Value(stamp.device),
    ));
  }

  Future<double> cachedQty(String id) async =>
      (await db.productsDao.getById(id))!.quantity;

  group('on-hand is the sum of the log', () {
    test('movements accumulate into the cached quantity', () async {
      await addProduct('p1');
      expect(await cachedQty('p1'), 0);

      await move('m1', 'p1', 10, reason: 'openingBalance');
      expect(await cachedQty('p1'), 10);

      await move('m2', 'p1', -3);
      expect(await cachedQty('p1'), 7);

      await move('m3', 'p1', 2.5);
      expect(await cachedQty('p1'), 9.5,
          reason: 'stock is double app-wide — 0.5 kg is a real movement');
    });

    test('the cache floors at zero but the log keeps the truth', () async {
      await addProduct('p1');
      await move('m1', 'p1', 2);
      await move('m2', 'p1', -5); // oversold a loose item

      expect(await cachedQty('p1'), 0,
          reason: 'shipped behaviour: no screen shows negative stock');
      expect(await db.stockDao.derivedOnHand('p1'), -3,
          reason: 'the honest figure survives for reconciliation');
    });

    test('the floor is applied to the sum, not to each step', () async {
      // The old `MAX(quantity - ?, 0)` clamped as it went, so overselling by 3
      // and then restocking 5 left the shop believing it had 5. Recomputing
      // from the whole log gets the arithmetic right.
      await addProduct('p1');
      await move('m1', 'p1', 2);
      await move('m2', 'p1', -5);
      await move('m3', 'p1', 5);

      expect(await cachedQty('p1'), 2);
    });

    test('reversing a source tombstones its movements and recomputes',
        () async {
      await addProduct('p1');
      await move('m1', 'p1', 10, reason: 'openingBalance');
      await move('m2', 'p1', -4, reason: 'sale', relatedId: 'inv9');
      expect(await cachedQty('p1'), 6);

      await db.stockDao
          .reverseByRelatedIdInTransaction('inv9', await clock.stamp());

      expect(await cachedQty('p1'), 10, reason: 'only the sale was undone');
      expect((await db.stockDao.getMovements('p1')).map((m) => m.id), ['m1']);
    });
  });

  group('setOnHand records a difference, never an absolute', () {
    test('a correction is stored as the delta from the current sum', () async {
      await addProduct('p1');
      await move('m1', 'p1', 10);

      final delta = await db.stockDao.setOnHand(
        productId: 'p1',
        target: 8,
        movementId: 'fix1',
        reason: 'adjustment',
        now: 2000,
        stamp: await clock.stamp(),
      );

      expect(delta, -2);
      expect(await cachedQty('p1'), 8);
      // A stored "8" would be the last-write-wins scalar Plan 002 rejects: a
      // concurrent sale on another device would be erased by it. A stored "−2"
      // composes with whatever else happened.
      final rows = await db.stockDao.getMovements('p1');
      expect(rows.map((m) => m.delta).toList(), [-2, 10]);
    });

    test('saving an unchanged quantity writes nothing', () async {
      await addProduct('p1');
      await move('m1', 'p1', 10);

      final delta = await db.stockDao.setOnHand(
        productId: 'p1',
        target: 10,
        movementId: 'noop',
        reason: 'adjustment',
        now: 2000,
        stamp: await clock.stamp(),
      );

      expect(delta, 0);
      expect((await db.stockDao.getMovements('p1')).length, 1,
          reason: 'a form that round-trips must not litter the log');
    });

    test('it measures against the log, not the cached column', () async {
      await addProduct('p1');
      await move('m1', 'p1', 2);
      await move('m2', 'p1', -5); // cache floors to 0, true sum is -3

      await db.stockDao.setOnHand(
        productId: 'p1',
        target: 4,
        movementId: 'fix1',
        reason: 'adjustment',
        now: 2000,
        stamp: await clock.stamp(),
      );

      // Measured against the cache (0) this would have written +4 and left the
      // real sum at 1 — the floor's white lie baked permanently into the log.
      expect(await db.stockDao.derivedOnHand('p1'), 4);
      expect(await cachedQty('p1'), 4);
    });
  });

  group('sales write movements', () {
    Future<void> sell(String invoiceId, double qty) async =>
        db.salesDao.insertInvoiceWithItems(
          stamp: await clock.stamp(),
          invoice: SalesInvoicesCompanion.insert(
            id: invoiceId,
            createdAt: 1000,
            totalAmount: 5000 * qty,
          ),
          items: [
            SalesItemsCompanion.insert(
              invoiceId: invoiceId,
              productId: 'p1',
              productName: 'منتج p1',
              price: 5000,
              quantity: qty,
              uuid: Value('$invoiceId-0'),
            ),
          ],
        );

    test('a sale deducts by appending, and the deduction is reversible',
        () async {
      await addProduct('p1');
      await move('m1', 'p1', 10, reason: 'openingBalance');

      await sell('inv1', 3);
      expect(await cachedQty('p1'), 7);
      final sold = (await db.stockDao.getMovements('p1'))
          .firstWhere((m) => m.reason == 'sale');
      expect(sold.delta, -3);
      expect(sold.relatedId, 'inv1',
          reason: 'the link that lets a deleted invoice find its movements');

      await db.salesDao.softDeleteInvoice('inv1', await clock.stamp());
      expect(await cachedQty('p1'), 10,
          reason: 'deleting the sale puts the stock back');
    });

    test('two sales of the last unit both count — the whole point', () async {
      // Precisely the case Plan 002 opens with. Under the old scalar the second
      // deduction overwrote the first and one sale left no trace in stock;
      // as movements they simply add up.
      await addProduct('p1');
      await move('m1', 'p1', 5, reason: 'openingBalance');

      await sell('inv1', 1);
      await sell('inv2', 1);

      expect(await cachedQty('p1'), 3);
      expect((await db.stockDao.getMovements('p1')).length, 3);
    });

    test('the movement id is derived, so a replayed sale cannot double-deduct',
        () async {
      await addProduct('p1');
      await move('m1', 'p1', 10, reason: 'openingBalance');
      await sell('inv1', 2);

      // Same invoice arriving twice (a retried push, a re-applied change).
      await expectLater(sell('inv1', 2), throwsA(anything));
      expect(await cachedQty('p1'), 8);
    });
  });

  group('serialized products keep units as their only authority', () {
    test('on-hand follows the unit count, not the movement log', () async {
      await addProduct('p2', serialized: true);
      await db.productUnitsDao.insertUnit(ProductUnitsCompanion.insert(
        id: 'u1',
        productId: 'p2',
        serial: 'IMEI-1',
        createdAt: 1000,
      ));
      await db.productUnitsDao.insertUnit(ProductUnitsCompanion.insert(
        id: 'u2',
        productId: 'p2',
        serial: 'IMEI-2',
        createdAt: 1000,
      ));
      expect(await cachedQty('p2'), 2);

      // A stray movement must not move a serialized SKU's on-hand: its units
      // already ARE an append-only, uuid-keyed, merge-safe log, and a second
      // ledger could only disagree with them.
      await move('m1', 'p2', 99);
      expect(await cachedQty('p2'), 2);

      await db.productUnitsDao.softDeleteUnit('u1', await clock.stamp());
      expect(await cachedQty('p2'), 1);
    });
  });

  group('v17 → v18 migration', () {
    test('existing stock is backfilled as an opening balance', () async {
      await db.close();
      dbFile.deleteSync();

      // A "v17" shop: quantity is still the truth, no log exists.
      var old = AppDatabase.forTesting(NativeDatabase(dbFile));
      await old.customStatement(
          "INSERT INTO products (id,name,barcode,price,quantity) "
          "VALUES ('p1','رز','BR-1',5000,12)");
      await old.customStatement(
          "INSERT INTO products (id,name,price,quantity) "
          "VALUES ('p2','بقدونس',1000,0)");
      await old.customStatement(
          "INSERT INTO products (id,name,price,quantity,is_serialized) "
          "VALUES ('p3','هاتف',5000000,1,1)");
      await stripV19(old);
      await stripV18(old);
      await old.customStatement('PRAGMA user_version = 17');
      await old.close();

      final fresh = AppDatabase.forTesting(NativeDatabase(dbFile));

      // Without the backfill the first recompute would zero every count — the
      // migration would look like it deleted the shop's entire inventory.
      final movements = await fresh.stockDao.getMovements('p1');
      expect(movements.length, 1);
      expect(movements.single.delta, 12);
      expect(movements.single.reason, 'openingBalance');
      expect(movements.single.id, 'opening-p1',
          reason: 'deterministic, so two devices migrating produce one row');
      expect(movements.single.updatedAt, '',
          reason: 'reconstructed history must not beat a real remote edit');

      // Zero-stock products get no movement — an empty log already sums to 0.
      expect(await fresh.stockDao.getMovements('p2'), isEmpty);
      // Serialized SKUs are skipped: their units are the log.
      expect(await fresh.stockDao.getMovements('p3'), isEmpty);

      // And the shop still sees exactly what it saw before upgrading.
      final rows = await fresh
          .customSelect('SELECT id, quantity FROM products ORDER BY id')
          .get();
      expect(rows.map((r) => r.read<double>('quantity')).toList(),
          [12.0, 0.0, 1.0]);

      await fresh.close();
      db = AppDatabase.forTesting(NativeDatabase(dbFile)); // for tearDown
    });
  });
}
