// When a sync pass runs (Plan 002, Phase 1).
//
// A host test with fakes, because the question here is scheduling policy, not
// SQL: does an unenrolled device stay completely inert, does a burst of writes
// coalesce into one pass, does a doorbell work, and can a trigger firing inside
// a Timer callback ever throw. Convergence itself is proved on a device by
// `integration_test/sync_engine_test.dart`.
import 'dart:async';

import 'package:billing_app/core/database/daos/sync_dao.dart';
import 'package:billing_app/features/sync/data/sync_credential_store.dart';
import 'package:billing_app/features/sync/data/sync_engine.dart';
import 'package:billing_app/features/sync/data/sync_scheduler.dart';
import 'package:billing_app/features/sync/domain/entities/sync_outcome.dart';
import 'package:billing_app/features/sync/domain/entities/sync_seat_role.dart';
import 'package:billing_app/features/sync/domain/entities/sync_session.dart';
import 'package:billing_app/features/sync/domain/sync_error.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCredentials implements SyncCredentialStore {
  SyncSession? session;
  _FakeCredentials([this.session]);

  @override
  Future<SyncSession?> load() async => session;

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName} not needed');
}

class _CountingEngine implements SyncEngine {
  int passes = 0;
  SyncOutcome result = const SyncOutcome(pushed: 1);
  Object? throws;

  /// Held open by a test that wants a pass still running when something else
  /// fires — which is the whole situation the doorbell has to survive.
  Completer<void>? gate;

  @override
  bool isSyncing = false;

  @override
  Future<SyncOutcome> sync() async {
    passes++;
    isSyncing = true;
    try {
      final held = gate;
      if (held != null) await held.future;
      final t = throws;
      if (t != null) throw t;
      return result;
    } finally {
      isSyncing = false;
    }
  }

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName} not needed');
}

class _FakeSyncDao implements SyncDao {
  final controller = const Stream<void>.empty();

  @override
  Stream<void> watchLocalChanges() => controller;

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName} not needed');
}

const _session = SyncSession(
  syncToken: 'tok',
  businessUuid: 'biz',
  seatUuid: 'seat',
  role: SyncSeatRole.member,
  deviceAllowance: 3,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CountingEngine engine;
  late _FakeCredentials credentials;

  SyncScheduler build({SyncSession? session}) {
    engine = _CountingEngine();
    credentials = _FakeCredentials(session);
    return SyncScheduler(
      engine: engine,
      credentials: credentials,
      dao: _FakeSyncDao(),
      interval: const Duration(milliseconds: 40),
      debounce: const Duration(milliseconds: 10),
    );
  }

  test('an unenrolled device never syncs', () async {
    final scheduler = build(); // no session
    await scheduler.start();
    scheduler.onRemoteChange();
    await scheduler.syncNow();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // The gate that keeps this feature free for the single-device shops that
    // are most of the install base — no database read, no request, no timer
    // work that reaches the engine.
    expect(engine.passes, 0);
    scheduler.dispose();
  });

  test('start() syncs once on launch', () async {
    final scheduler = build(session: _session);
    await scheduler.start();
    expect(engine.passes, 1);

    // Idempotent — main() and a settings screen may both call it, and a second
    // observer + timer would double every trigger from then on.
    await scheduler.start();
    expect(engine.passes, 1);
    scheduler.dispose();
  });

  test('the doorbell triggers a pass', () async {
    final scheduler = build(session: _session);
    await scheduler.start();
    scheduler.onRemoteChange();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(engine.passes, 2, reason: 'launch + doorbell');
    scheduler.dispose();
  });

  test('a doorbell during a pass gets its own pass afterwards', () async {
    final scheduler = build(session: _session);
    final gate = Completer<void>();
    engine.gate = gate;

    final launch = scheduler.start(); // pass 1, held open
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(engine.passes, 1);

    scheduler.onRemoteChange(); // rings mid-pass
    await Future<void>.delayed(const Duration(milliseconds: 5));
    // It must NOT have joined: pass 1 has already read its cursor and cannot
    // see the change being announced, so joining it would make the ring a
    // no-op and leave the other till's sale waiting out the 5-minute timer —
    // exactly the delay the doorbell exists to remove.
    expect(engine.passes, 1, reason: 'not started, and not joined either');

    engine.gate = null;
    gate.complete();
    await launch;

    expect(engine.passes, 2, reason: 'the deferred doorbell pass ran');
    scheduler.dispose();
  });

  test('a burst of doorbells during one pass costs one follow-up', () async {
    final scheduler = build(session: _session);
    final gate = Completer<void>();
    engine.gate = gate;

    final launch = scheduler.start();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    for (var i = 0; i < 5; i++) {
      scheduler.onRemoteChange();
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));

    engine.gate = null;
    gate.complete();
    await launch;

    // Bounded on purpose. A busy shop rings this on every sale the other till
    // makes; one follow-up catches all of them, and chaining a pass per ring
    // would put a phone on a shop's mobile data in a loop.
    expect(engine.passes, 2);
    scheduler.dispose();
  });

  test('the periodic timer keeps running', () async {
    final scheduler = build(session: _session);
    await scheduler.start();
    await Future<void>.delayed(const Duration(milliseconds: 130));

    expect(engine.passes, greaterThan(1));
    scheduler.dispose();

    // A pass already in flight is allowed to finish rather than being
    // abandoned — a push that is halfway to the server should land. So settle
    // first, then assert nothing NEW starts: a leaked periodic timer would keep
    // hitting the network for the life of the process.
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final after = engine.passes;
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(engine.passes, after,
        reason: 'dispose() must stop the periodic timer');
  });

  test('the last outcome is published for the UI', () async {
    final scheduler = build(session: _session);
    engine.result = const SyncOutcome(pushed: 3, pulled: 7);
    await scheduler.start();

    expect(scheduler.lastOutcome.value?.pushed, 3);
    expect(scheduler.lastOutcome.value?.pulled, 7);
    expect(scheduler.isSyncing.value, isFalse);
    scheduler.dispose();
  });

  test('a failing pass never throws out of a trigger', () async {
    // A trigger runs inside a Timer callback and a lifecycle handler. An
    // unhandled error there takes down the zone — and this is a background
    // nicety, not something worth crashing a till over mid-sale.
    final scheduler = build(session: _session);
    engine.throws = StateError('boom');

    await expectLater(scheduler.start(), completes);
    expect(scheduler.isSyncing.value, isFalse,
        reason: 'the spinner must not stick on after a failure');
    scheduler.dispose();
  });

  test('a reported failure is published, not swallowed', () async {
    final scheduler = build(session: _session);
    engine.result = const SyncOutcome(error: SyncError.offline);
    await scheduler.start();

    expect(scheduler.lastOutcome.value?.isSuccess, isFalse);
    expect(scheduler.lastOutcome.value?.error, SyncError.offline);
    scheduler.dispose();
  });

  test('syncNow works before start, for an explicit user action', () async {
    // A "Sync now" button on a settings page must work even if the scheduler
    // has not been started yet (a screen reached before main()'s fire-and-forget
    // start completed).
    final scheduler = build(session: _session);
    final outcome = await scheduler.syncNow();

    expect(outcome, isNotNull);
    expect(engine.passes, 1);
    scheduler.dispose();
  });
}
