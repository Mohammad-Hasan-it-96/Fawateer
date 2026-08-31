// The sync engine, driven end-to-end between TWO real databases (Plan 002,
// Phase 1).
//
// Every other test in this suite exercises one device. Convergence cannot be
// tested that way: the whole question is whether two independently-written
// databases end up agreeing, and mocking one side proves only that the mock
// agrees with itself. So this runs two real `AppDatabase`s with different node
// ids against a shared in-memory relay that behaves like the negotiated
// endpoints — per-business seq, ascending pull, echoes included.
//
// On a device because the merge is SQL: dynamically-built upserts, HLC string
// comparison in SQLite, and a derived-quantity rebuild after every batch.
//
// Run: flutter test integration_test/sync_engine_test.dart -d <deviceId>
import 'dart:io';

import 'package:billing_app/core/database/app_database.dart';
import 'package:billing_app/features/sync/data/sync_engine.dart';
import 'package:billing_app/features/sync/data/sync_state_store.dart';
import 'package:billing_app/features/sync/domain/entities/sync_change.dart';
import 'package:billing_app/features/sync/domain/sync_transport.dart';
// `isNull`/`isNotNull` collide with drift's SQL builder; the matchers are
// what is meant here.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'sync_relay.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SyncRelay relay;
  late TestDevice a;
  late TestDevice b;

  setUp(() async {
    relay = SyncRelay();
    a = await TestDevice.create('a', 'nodeAAAAAAAAAAAA', relay);
    b = await TestDevice.create('b', 'nodeBBBBBBBBBBBB', relay);
  });

  tearDown(() async {
    await a.dispose();
    await b.dispose();
  });

  /// Both devices push then pull until quiet. Twice, because A's changes only
  /// become visible to B after A has pushed — one round each is not enough for
  /// a change made on B *after* it pulled from A.
  Future<void> settle() async {
    for (var i = 0; i < 2; i++) {
      await a.engine.sync();
      await b.engine.sync();
    }
  }

  Future<void> addProduct(TestDevice d, String id, String name,
      {double qty = 0, String barcode = ''}) async {
    final stamp = await d.clock.stamp();
    await d.db.productsDao.createProduct(ProductsCompanion.insert(
      id: id,
      name: name,
      barcode: Value(barcode),
      price: 5000,
      cost: const Value(3000),
      updatedAt: Value(stamp.hlc),
      originDevice: Value(stamp.device),
    ));
    if (qty != 0) {
      await d.db.stockDao.setOnHand(
        productId: id,
        target: qty,
        movementId: 'open-$id-${d.name}',
        reason: 'openingBalance',
        now: 1000,
        stamp: await d.clock.stamp(),
      );
    }
  }

  Future<void> rename(TestDevice d, String id, String name) async {
    final stamp = await d.clock.stamp();
    await d.db.customUpdate(
      'UPDATE products SET name = ?, updated_at = ?, origin_device = ? '
      'WHERE id = ?',
      variables: [
        Variable<String>(name),
        Variable<String>(stamp.hlc),
        Variable<String>(stamp.device),
        Variable<String>(id),
      ],
      updates: {d.db.products},
    );
  }

  Future<String?> nameOf(TestDevice d, String id) async =>
      (await d.db.productsDao.getById(id))?.name;

  Future<double> qtyOf(TestDevice d, String id) async =>
      (await d.db.productsDao.getById(id))?.quantity ?? -1;

  group('replication', () {
    test('a product created on one till appears on the other', () async {
      await addProduct(a, 'p1', 'رز', qty: 5, barcode: 'BR-1');
      await settle();

      final onB = await b.db.productsDao.getById('p1');
      expect(onB, isNotNull, reason: 'the catalogue must reach the second till');
      expect(onB!.name, 'رز');
      expect(onB.barcode, 'BR-1');
      expect(await qtyOf(b, 'p1'), 5,
          reason: 'and its stock, rebuilt from the movement that came with it');
    });

    test('the authoring device is preserved through the relay', () async {
      await addProduct(a, 'p1', 'رز');
      await settle();

      final onB = await b.db
          .customSelect("SELECT origin_device FROM products WHERE id = 'p1'")
          .getSingle();
      expect(onB.read<String>('origin_device'), 'nodeAAAAAAAAAAAA',
          reason: 'a relayed row must not be re-stamped by the forwarder — '
              'the owner has to be able to see which till changed a price');
    });

    test('syncing again changes nothing', () async {
      await addProduct(a, 'p1', 'رز', qty: 5);
      await settle();

      final second = await b.engine.sync();
      expect(second.pulled, 0,
          reason: 'a page of already-applied changes must apply nothing');
      expect(await qtyOf(b, 'p1'), 5, reason: 'and must not double-count stock');
    });

    test('an echo of our own push cannot clobber a newer local edit', () async {
      // The relay echoes everything, so A pulls back the row it just pushed.
      // If that applied blindly it would revert an edit made in between.
      await addProduct(a, 'p1', 'رز');
      await a.engine.sync();
      await rename(a, 'p1', 'رز بسمتي');
      await a.engine.sync();

      expect(await nameOf(a, 'p1'), 'رز بسمتي');
    });
  });

  group('deletes travel', () {
    test('a delete on one till does not resurrect from the other', () async {
      await addProduct(a, 'p1', 'رز');
      await settle();
      expect(await nameOf(b, 'p1'), 'رز');

      await a.db.productsDao.softDeleteProduct('p1', await a.clock.stamp());
      await settle();

      expect(await b.db.productsDao.getById('p1'), isNull,
          reason: 'the single most corrosive sync bug is the row coming back');
      // And it stays gone across another round — a resurrection would show up
      // as the row reappearing once B pushes its (now stale) copy back.
      await settle();
      expect(await b.db.productsDao.getById('p1'), isNull);
      expect(await a.db.productsDao.getById('p1'), isNull);
    });

    test('a delete racing an edit converges — both tills agree', () async {
      await addProduct(a, 'p1', 'رز');
      await settle();

      // The genuinely concurrent case: A deletes while B, which has not yet
      // seen the delete, renames. Both are legitimate; the shop must not end up
      // with the product on one till and not the other.
      await a.db.productsDao.softDeleteProduct('p1', await a.clock.stamp());
      await rename(b, 'p1', 'رز جديد');
      await settle();
      await settle();

      // Deliberately NOT asserting which one wins. The tombstone is just
      // another field under last-write-wins, so the winner depends on the two
      // stamps — and pinning it here would be pinning the wall clock. What must
      // hold is that the tills do not disagree, which is the failure that
      // actually hurts a shop.
      final liveOnA = await a.db.productsDao.getById('p1');
      final liveOnB = await b.db.productsDao.getById('p1');
      expect(liveOnA?.name, liveOnB?.name,
          reason: 'divergence is the failure that matters');

      final rawA = await a.db
          .customSelect("SELECT deleted_at FROM products WHERE id = 'p1'")
          .getSingle();
      final rawB = await b.db
          .customSelect("SELECT deleted_at FROM products WHERE id = 'p1'")
          .getSingle();
      expect(rawA.read<String>('deleted_at'), rawB.read<String>('deleted_at'),
          reason: 'the tombstone itself must converge too, not just the name');
    });
  });

  group('concurrent edits converge', () {
    test('both tills end up with the SAME name, not just some name', () async {
      await addProduct(a, 'p1', 'رز');
      await settle();

      // Neither has seen the other's edit when it makes its own.
      await rename(a, 'p1', 'من الجهاز أ');
      await rename(b, 'p1', 'من الجهاز ب');
      await settle();
      await settle();

      final onA = await nameOf(a, 'p1');
      final onB = await nameOf(b, 'p1');
      expect(onA, onB,
          reason: 'divergence is the failure that matters — which edit wins is '
              'secondary, that they agree is not');
      expect(onA, anyOf('من الجهاز أ', 'من الجهاز ب'));
    });
  });

  group('stock is conflict-free', () {
    test('two tills selling the last units both count', () async {
      // The case Plan 002 opens with. Held as a scalar and merged
      // last-write-wins these two sales converge on "4" and one disappears.
      await addProduct(a, 'p1', 'رز', qty: 5);
      await settle();
      expect(await qtyOf(b, 'p1'), 5);

      await sell(a, 'invA', 1);
      await sell(b, 'invB', 1);
      await settle();
      await settle();

      expect(await qtyOf(a, 'p1'), 3, reason: 'both sales must be deducted');
      expect(await qtyOf(b, 'p1'), 3);
      expect(await a.db.stockDao.derivedOnHand('p1'), 3);
      expect(await b.db.stockDao.derivedOnHand('p1'), 3);
    });

    test('both invoices and both sets of lines survive', () async {
      await addProduct(a, 'p1', 'رز', qty: 5);
      await settle();

      await sell(a, 'invA', 1);
      await sell(b, 'invB', 2);
      await settle();
      await settle();

      for (final d in [a, b]) {
        final invoices = await d.db.salesDao.getAllInvoices();
        expect(invoices.map((i) => i.id).toSet(), {'invA', 'invB'},
            reason: '${d.name} lost an invoice');
        expect((await d.db.salesDao.getItemsForInvoice('invA')).length, 1);
        expect((await d.db.salesDao.getItemsForInvoice('invB')).length, 1);
      }
    });

    test('a line never arrives before its invoice', () async {
      // Apply order is by kSyncTables, parents first. Checked by asserting the
      // audit list — which counts lines per invoice — is coherent immediately
      // after the batch rather than eventually.
      await addProduct(a, 'p1', 'رز', qty: 5);
      await settle();
      await sell(a, 'invA', 1);
      await a.engine.sync();
      await b.engine.sync();

      final rows = await b.db.salesDao
          .watchAuditInvoices(
            fromMs: 0,
            toMs: 99999999,
            payment: 'all',
            search: '',
            orderBySql: 'i.created_at DESC',
            limit: 30,
            offset: 0,
          )
          .first;
      expect(rows.length, 1);
      expect(rows.single.itemCount, 1);
    });
  });

  group('a relayed null never wedges the device', () {
    // evotech-core runs Laravel's default `ConvertEmptyStringsToNull`
    // middleware, which rewrites every empty string in a request to null —
    // recursively, through arrays. Our push payload IS a nested array of the
    // row's columns, so every `''` in it went up as `''`, was stored as null,
    // and came back to the other phone as null.
    //
    // The in-memory relay cannot reproduce that (it hands the payload back
    // byte-identical, which is right for what it exists to prove), so these
    // drive the applier directly with the payload the real server sends.
    //
    // The cost of getting this wrong is not one lost row. `applyChanges` runs
    // in a single transaction, so the constraint failure aborts the whole page,
    // the pull cursor never advances, and every later pass re-reads the same
    // page and dies the same way. Seen in the field on 2026-08-31: a stock edit
    // on the second phone, then `NOT NULL constraint failed:
    // stock_movements.deleted_at` on every sync from then on, permanently.

    /// The row exactly as it came off the wire in that report.
    SyncChange movementWithNulls(String hlc) => SyncChange(
          table: 'stock_movements',
          rowUuid: '22a15068-ca4f-4271-82fa-9167177ed95d',
          op: SyncChange.opUpsert,
          authoredHlc: hlc,
          originDevice: 'nodeBBBBBBBBBBBB',
          payload: {
            'id': '22a15068-ca4f-4271-82fa-9167177ed95d',
            'product_id': 'p1',
            'delta': -200.0,
            'reason': 'adjustment',
            'occurred_at': 1788208543682,
            'created_at': 1788208543682,
            // All three are TEXT NOT NULL DEFAULT '' locally. All three
            // arrived null.
            'note': null,
            'related_id': null,
            'deleted_at': null,
            'updated_at': hlc,
            'origin_device': 'nodeBBBBBBBBBBBB',
          },
        );

    test('an empty string relayed as null is restored, not rejected', () async {
      await addProduct(a, 'p1', 'رز', qty: 500);
      final hlc = (await b.clock.stamp()).hlc;

      final applied = await a.db.syncDao.applyChanges([movementWithNulls(hlc)]);

      expect(applied, 1, reason: 'the row must land, not abort the batch');
      final row = await a.db
          .customSelect(
              "SELECT deleted_at, note, related_id FROM stock_movements "
              "WHERE id = '22a15068-ca4f-4271-82fa-9167177ed95d'")
          .getSingle();
      // '' and not null: '' is the only value that middleware turns into null,
      // so this is the sender's real value restored, not a guess.
      expect(row.data['deleted_at'], '');
      expect(row.data['note'], '');
      expect(row.data['related_id'], '');
    });

    test('the movement still counts toward on-hand', () async {
      // A row that landed but did not reach the quantity rebuild would be the
      // same bug one layer down — silent instead of loud.
      await addProduct(a, 'p1', 'رز', qty: 500);
      final hlc = (await b.clock.stamp()).hlc;

      await a.db.syncDao.applyChanges([movementWithNulls(hlc)]);

      expect(await a.db.stockDao.derivedOnHand('p1'), 300);
    });

    test('an unwritable row is skipped, and its page still lands', () async {
      // `occurred_at` is INTEGER NOT NULL with no default, so a null there
      // cannot be repaired OR dropped — an insert missing it fails just as
      // loudly. There is nothing to invent, so the row is skipped.
      //
      // Two rows, deliberately: the point is not that the bad one is dropped,
      // it is that the GOOD one still lands. Before this, one unwritable row
      // aborted the transaction, the cursor stayed put, and every later pass
      // re-read the same page and died identically.
      await addProduct(a, 'p1', 'رز', qty: 500);
      final good = movementWithNulls((await b.clock.stamp()).hlc);
      final broken = SyncChange(
        table: good.table,
        rowUuid: 'broken-row',
        op: good.op,
        authoredHlc: (await b.clock.stamp()).hlc,
        originDevice: good.originDevice,
        payload: {...good.payload, 'id': 'broken-row', 'occurred_at': null},
      );

      final applied = await a.db.syncDao.applyChanges([broken, good]);

      expect(applied, 1, reason: 'the good row must survive the bad one');
      expect(await a.db.stockDao.derivedOnHand('p1'), 300);
    });
  });

  group('what the scheduler listens to', () {
    test('a received row is not pushed straight back', () async {
      await addProduct(a, 'p1', 'رز');
      await settle();
      expect(await nameOf(b, 'p1'), 'رز');

      // B now holds a row whose authored HLC is ABOVE B's own push watermark.
      // Without the origin filter B would collect it and push it back, and the
      // two tills would spend every tick echoing each other's traffic.
      final mine = await b.db.syncDao
          .collectSince('', originDevice: 'nodeBBBBBBBBBBBB');
      expect(mine.where((c) => c.rowUuid == 'p1'), isEmpty,
          reason: 'a row we did not author came FROM the server — it has it');

      // And it is still collectable by the device that did author it, so the
      // filter has not simply hidden everything.
      final theirs = await a.db.syncDao
          .collectSince('', originDevice: 'nodeAAAAAAAAAAAA');
      expect(theirs.map((c) => c.rowUuid), contains('p1'));
    });

    test('a local write wakes the change ticker', () async {
      // What the scheduler debounces on. Faked in the host test, so this is the
      // only place it meets real Drift.
      final fired = a.db.syncDao.watchLocalChanges().first;
      await addProduct(a, 'p1', 'رز');
      await expectLater(fired.timeout(const Duration(seconds: 5)), completes);
    });
  });

  group('the engine protects its own position', () {
    test('a rejected row stops the watermark so nothing is stranded', () async {
      await addProduct(a, 'p1', 'رز');
      await addProduct(a, 'p2', 'سكر');
      relay.refuse.add('p1');

      final first = await a.engine.sync();
      expect(first.rejected, greaterThan(0));

      // p1 is refused, so the watermark must not step over it — otherwise p2
      // syncs, p1 never does, and nothing ever notices.
      relay.refuse.clear();
      await settle();

      expect(await nameOf(b, 'p1'), 'رز',
          reason: 'the refused row must be retried, not silently dropped');
      expect(await nameOf(b, 'p2'), 'سكر');
    });

    test('a backlog drains across pages', () async {
      for (var i = 0; i < 120; i++) {
        await addProduct(a, 'p$i', 'صنف $i');
      }
      await settle();

      final onB = await b.db.productsDao.getAllProducts();
      expect(onB.length, 120,
          reason: 'paging must not lose the tail of a backlog');
    });

    test('an offline pass reports offline and keeps its place', () async {
      await addProduct(a, 'p1', 'رز');
      final dead = SyncEngine(
        dao: a.db.syncDao,
        transport: _OfflineTransport(),
        state: SyncStateStore(a.db.settingsDao),
        clock: a.clock,
      );

      final outcome = await dead.sync();
      expect(outcome.isSuccess, isFalse);
      expect(outcome.pushed, 0);

      // The real engine then still has the change to send.
      await settle();
      expect(await nameOf(b, 'p1'), 'رز');
    });
  });
}

/// A sale on one till, written through the real sale path so the movement,
/// invoice and line all get their stamps the way production does.
// ignore: library_private_types_in_public_api  — a test-local helper type
Future<void> sell(TestDevice d, String invoiceId, double qty) async {
  final stamp = await d.clock.stamp();
  await d.db.salesDao.insertInvoiceWithItems(
    stamp: stamp,
    invoice: SalesInvoicesCompanion.insert(
      id: invoiceId,
      createdAt: 1000,
      totalAmount: 5000 * qty,
      updatedAt: Value(stamp.hlc),
      originDevice: Value(stamp.device),
    ),
    items: [
      SalesItemsCompanion.insert(
        invoiceId: invoiceId,
        productId: 'p1',
        productName: 'رز',
        price: 5000,
        quantity: qty,
        uuid: Value('$invoiceId-0'),
        updatedAt: Value(stamp.hlc),
        originDevice: Value(stamp.device),
      ),
    ],
  );
}

class _OfflineTransport implements SyncTransport {
  @override
  Future<PushResult> push(List<SyncChange> changes) async =>
      throw const SocketException('offline');

  @override
  Future<PullPage> pull({required int since, int limit = 200}) async =>
      throw const SocketException('offline');
}
