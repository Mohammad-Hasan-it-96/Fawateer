// A stand-in for the sync backend, shared by every convergence test.
//
// Deliberately ONE definition. Two test files each with their own idea of how
// the server sequences and pages would be two chances to encode a different
// server — and a divergence between them would look exactly like the asymmetry
// `kSyncTables` exists to prevent: one test proving replication works against a
// relay the other test's behaviour contradicts.
import 'dart:io';

import 'package:billing_app/core/database/app_database.dart';
import 'package:billing_app/core/sync/sync_clock.dart';
import 'package:billing_app/features/sync/data/sync_engine.dart';
import 'package:billing_app/features/sync/data/sync_state_store.dart';
import 'package:billing_app/features/sync/domain/entities/sync_change.dart';
import 'package:billing_app/features/sync/domain/sync_transport.dart';
import 'package:drift/native.dart';

/// Stands in for `device_changes`: an append-only oplog with a per-business
/// sequence, exactly the shape the backend committed to.
class SyncRelay {
  final List<SyncChange> log = [];
  int _seq = 0;

  /// Row uuids to refuse, so the stranding guard can be exercised.
  final Set<String> refuse = {};

  /// The server's current head — what a `last_seq` read would return.
  int get head => _seq;

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
      final duplicate = log.any((e) => e.idempotencyKey == c.idempotencyKey);
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

class RelayTransport implements SyncTransport {
  final SyncRelay relay;
  RelayTransport(this.relay);

  @override
  Future<PushResult> push(List<SyncChange> changes) async =>
      relay.accept(changes);

  @override
  Future<PullPage> pull({required int since, int limit = 200}) async =>
      relay.read(since, limit);
}

/// One simulated till: its own database file, clock and engine.
class TestDevice {
  final String name;
  final File file;
  final AppDatabase db;
  final SyncClock clock;
  final SyncEngine engine;

  TestDevice(this.name, this.file, this.db, this.clock, this.engine);

  static File pathFor(String name) => File(
      '${Directory.systemTemp.path}/fawateer_sync_${name}_${DateTime.now().microsecondsSinceEpoch}.sqlite');

  static Future<TestDevice> create(
    String name,
    String node,
    SyncRelay relay, {
    File? at,
  }) async {
    final file = at ?? pathFor(name);
    if (at == null && file.existsSync()) file.deleteSync();
    return open(name, node, relay, file);
  }

  /// Open a device over an existing file — what an app restart does after a
  /// bootstrap restore has swapped the database underneath it.
  static Future<TestDevice> open(
    String name,
    String node,
    SyncRelay relay,
    File file,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase(file));
    final clock = SyncClock(db.settingsDao);
    await clock.load(node);
    final engine = SyncEngine(
      dao: db.syncDao,
      transport: RelayTransport(relay),
      state: SyncStateStore(db.settingsDao),
      clock: clock,
      batchSize: 50,
    );
    return TestDevice(name, file, db, clock, engine);
  }

  Future<void> dispose({bool deleteFile = true}) async {
    try {
      await db.close();
    } catch (_) {/* already closed by a restore */}
    if (deleteFile && file.existsSync()) file.deleteSync();
  }
}
