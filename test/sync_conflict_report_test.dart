// A push conflict must reach the shopkeeper, not be counted as a clean send
// (Plan 002, ADR 0011 §11.2 `device_conflicts`).
//
// The engine has always parsed `PushResult.conflicts` — it needs them for the
// watermark, since a conflicted row *did* land — and then dropped them on the
// floor. That made "12 changes sent" the only thing a shop could ever be told,
// including when two of those twelve disagreed with the other till. Fakes, not
// Drift: what is under test is the arithmetic the engine does with the server's
// answer.
import 'package:billing_app/core/database/daos/settings_dao.dart';
import 'package:billing_app/core/database/daos/sync_dao.dart';
import 'package:billing_app/core/sync/sync_clock.dart';
import 'package:billing_app/features/sync/data/sync_engine.dart';
import 'package:billing_app/features/sync/data/sync_state_store.dart';
import 'package:billing_app/features/sync/domain/entities/sync_change.dart';
import 'package:billing_app/features/sync/domain/sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';

SyncChange _change(String uuid, String hlc) => SyncChange(
      table: 'products',
      rowUuid: uuid,
      op: 'upsert',
      payload: {'id': uuid},
      authoredHlc: hlc,
      originDevice: 'node',
    );

class _FakeSettings implements SettingsDao {
  final Map<String, String> store = {};

  @override
  Future<String?> getValue(String key) async => store[key];

  @override
  Future<void> setValue(String key, String value) async => store[key] = value;

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName} not needed');
}

/// Hands over one batch and then nothing, so a pass terminates.
class _OneBatchDao implements SyncDao {
  _OneBatchDao(this.pending);

  final List<SyncChange> pending;
  bool drained = false;

  @override
  Future<List<SyncChange>> collectSince(String watermark,
      {String? originDevice, int limit = 200}) async {
    if (drained) return const [];
    drained = true;
    return pending;
  }

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName} not needed');
}

class _StubTransport implements SyncTransport {
  _StubTransport(this.result);

  final PushResult result;

  @override
  Future<PushResult> push(List<SyncChange> changes) async => result;

  @override
  Future<PullPage> pull({required int since, int limit = 200}) async =>
      PullPage(changes: const [], nextCursor: since, hasMore: false);
}

Future<SyncEngine> _engine(SyncDao dao, PushResult result) async {
  final settings = _FakeSettings();
  final clock = SyncClock(settings);
  await clock.load('node');
  return SyncEngine(
    dao: dao,
    transport: _StubTransport(result),
    state: SyncStateStore(settings),
    clock: clock,
  );
}

void main() {
  test('a conflicted row is counted as sent AND as a conflict', () async {
    final engine = await _engine(
      _OneBatchDao([_change('a', '1'), _change('b', '2')]),
      const PushResult(accepted: {'a'}, conflicts: {'b'}),
    );

    final outcome = await engine.sync();

    // Both are on the server, so both are "sent" — reporting the conflicted one
    // as unsent would have the shopkeeper waiting for a retry that will never
    // come. But it is also named, because "2 sent" and "2 sent, 1 of which the
    // other phone had also changed" are different facts.
    expect(outcome.pushed, 2);
    expect(outcome.conflicts, 1);
    expect(outcome.rejected, 0);
    expect(outcome.isSuccess, isTrue);
  });

  test('a conflict is not a rejection and does not stall the watermark',
      () async {
    final dao = _OneBatchDao([_change('a', '1'), _change('b', '2')]);
    final engine = await _engine(
      dao,
      const PushResult(accepted: {}, conflicts: {'a', 'b'}),
    );

    await engine.sync();

    // A conflicted row the server kept must not be retried forever. If it held
    // the watermark, every subsequent sale would queue behind it and the shop
    // would silently stop replicating.
    expect(dao.drained, isTrue);
  });

  test('a clean pass reports no conflicts', () async {
    final engine = await _engine(
      _OneBatchDao([_change('a', '1')]),
      const PushResult(accepted: {'a'}),
    );

    final outcome = await engine.sync();

    expect(outcome.conflicts, 0);
    expect(outcome.pushed, 1);
  });
}
