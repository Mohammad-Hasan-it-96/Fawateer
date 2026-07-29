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
import 'package:billing_app/core/sync/sync_clock.dart';
import 'package:billing_app/features/sync/data/sync_engine.dart';
import 'package:billing_app/features/sync/data/sync_state_store.dart';
import 'package:billing_app/features/sync/domain/entities/sync_change.dart';
import 'package:billing_app/features/sync/domain/sync_transport.dart';
// `isNull`/`isNotNull` collide with drift's SQL builder; the matchers are
// what is meant here.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Stands in for `device_changes`: an append-only oplog with a per-business
/// sequence, exactly the shape the backend committed to.
class _Relay {
  final List<SyncChange> log = [];
  int _seq = 0;

  /// Row uuids to refuse, so the stranding guard can be exercised.
  final Set<String> refuse = {};

  PushResult accept(List<SyncChange> changes) {
    final accepted = <String>{};
    final rejected = <String>{};
    for (final c in changes) {
      if (refuse.contains(c.rowUuid)) {
        rejected.add(c.rowUuid);
        continue;
      }
      // UNIQUE(business_id, idempotency_key): a re-push of the same edit is a
      // no-op but still reports as accepted.
      final duplicate =
          log.any((e) => e.idempotencyKey == c.idempotencyKey);
      if (!duplicate) {
        log.add(SyncChange(
          table: c.table,
          rowUuid: c.rowUuid,
          op: c.op,
          payload: c.payload,
          authoredHlc: c.authoredHlc,
          // Preserved verbatim, never overwritten with the pusher — the rule
          // that keeps "which device changed this price" honest through a relay.
          originDevice: c.originDevice,
          seq: ++_seq,
        ));
      }
      accepted.add(c.rowUuid);
    }
    return PushResult(accepted: accepted, rejected: rejected);
  }

  PullPage read(int since, int limit) {
    final page = log.where((c) => (c.seq ?? 0) > since).take(limit).toList();
    final examined = log.isEmpty ? since : log.last.seq ?? since;
    final lastReturned = page.isEmpty ? since : page.last.seq!;
    final hasMore = log.any((c) => (c.seq ?? 0) > lastReturned);
    return PullPage(
      changes: page,
      // Highest seq EXAMINED when the page was not truncated, otherwise the
      // last one returned — the rule pinned on 2026-07-29.
      nextCursor: hasMore ? lastReturned : examined,
      hasMore: hasMore,
    );
  }
}

class _RelayTransport implements SyncTransport {
  final _Relay relay;
  _RelayTransport(this.relay);

  @override
  Future<PushResult> push(List<SyncChange> changes) async =>
      relay.accept(changes);

  @override
  Future<PullPage> pull({required int since, int limit = 200}) async =>
      relay.read(since, limit);
}

/// One simulated till: its own database, clock and engine.
class _Device {
  final String name;
  final File file;
  final AppDatabase db;
  final SyncClock clock;
  final SyncEngine engine;

  _Device(this.name, this.file, this.db, this.clock, this.engine);

  static Future<_Device> create(String name, String node, _Relay relay) async {
    final file = File(
        '${Directory.systemTemp.path}/fawateer_sync_${name}_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    if (file.existsSync()) file.deleteSync();
    final db = AppDatabase.forTesting(NativeDatabase(file));
    final clock = SyncClock(db.settingsDao);
    await clock.load(node);
    final engine = SyncEngine(
      dao: db.syncDao,
      transport: _RelayTransport(relay),
      state: SyncStateStore(db.settingsDao),
      clock: clock,
      batchSize: 50,
    );
    return _Device(name, file, db, clock, engine);
  }

  Future<void> dispose() async {
    await db.close();
    if (file.existsSync()) file.deleteSync();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _Relay relay;
  late _Device a;
  late _Device b;

  setUp(() async {
    relay = _Relay();
    a = await _Device.create('a', 'nodeAAAAAAAAAAAA', relay);
    b = await _Device.create('b', 'nodeBBBBBBBBBBBB', relay);
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

  Future<void> addProduct(_Device d, String id, String name,
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

  Future<void> rename(_Device d, String id, String name) async {
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

  Future<String?> nameOf(_Device d, String id) async =>
      (await d.db.productsDao.getById(id))?.name;

  Future<double> qtyOf(_Device d, String id) async =>
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
Future<void> sell(_Device d, String invoiceId, double qty) async {
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
