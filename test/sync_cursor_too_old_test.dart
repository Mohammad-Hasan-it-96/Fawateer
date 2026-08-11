// What happens when a phone has been away longer than the server keeps its
// change log (`CURSOR_TOO_OLD`, retention = 60 days in production).
//
// This is a host test with a fake transport on purpose: nothing here is SQL.
// The question is entirely about control flow — which half of a pass still
// runs, what the shop is told, and whether the app keeps asking a question the
// server can never answer again.
//
// It exists because the first version of this code had no case for the error at
// all: it fell through to `SyncError.server`, which the scheduler retries. The
// phone would never catch up, would keep spending the shop's data on a doomed
// request every few seconds, and would report an ordinary "something went
// wrong" while doing it.
import 'package:billing_app/core/database/app_database.dart';
import 'package:billing_app/core/database/daos/sync_dao.dart';
import 'package:billing_app/core/network/api_client.dart';
import 'package:billing_app/core/network/sync_api_client.dart';
import 'package:billing_app/core/sync/sync_clock.dart';
import 'package:billing_app/features/sync/data/sync_engine.dart';
import 'package:billing_app/features/sync/data/sync_state_store.dart';
import 'package:billing_app/features/sync/domain/entities/sync_change.dart';
import 'package:billing_app/features/sync/domain/sync_error.dart';
import 'package:billing_app/features/sync/domain/sync_transport.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// A transport whose pull always refuses with the server's pruned-watermark
/// code, and whose push always succeeds — the exact shape of a device that has
/// been offline past the retention window.
class _StaleCursorTransport implements SyncTransport {
  int pullCalls = 0;
  int pushCalls = 0;

  @override
  Future<PushResult> push(List<SyncChange> changes) async {
    pushCalls++;
    return PushResult(
      accepted: changes.map((c) => c.rowUuid).toSet(),
      rejected: const {},
      conflicts: const {},
    );
  }

  @override
  Future<PullPage> pull({required int since, int limit = 200}) async {
    pullCalls++;
    throw const SyncApiException(
        ApiErrorKind.server, 'too far behind', code: 'CURSOR_TOO_OLD');
  }

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SyncEngine engine;
  late _StaleCursorTransport transport;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final clock = SyncClock(db.settingsDao);
    await clock.load('testnode00000001');
    transport = _StaleCursorTransport();
    engine = SyncEngine(
      dao: SyncDao(db),
      transport: transport,
      state: SyncStateStore(db.settingsDao),
      clock: clock,
    );
  });

  tearDown(() async => db.close());

  /// A row authored by *this* device and not yet pushed — without one there is
  /// nothing to send, and "pushing still works" would pass on an empty
  /// database while proving nothing.
  ///
  /// [counter] must rise between rows: the push watermark is an authored HLC,
  /// so a second row stamped at the same position as the first sits *at* the
  /// watermark and is never collected — which is correct behaviour, and would
  /// silently make this test prove nothing.
  Future<void> seedUnpushedLocalRow(String id, int counter) =>
      db.customStatement(
          "INSERT INTO products (id,name,price,updated_at,origin_device) "
          "VALUES ('$id','عصير',1000,"
          "'9999999999999-${counter.toString().padLeft(5, '0')}-testnode00000001',"
          "'testnode00000001')");

  test('the server code is recognised, not lumped in with "server error"', () {
    // The whole bug in one line: unknown codes fall to SyncError.server, and
    // server is retryable.
    expect(SyncError.fromCode('CURSOR_TOO_OLD'), SyncError.cursorTooOld);
    expect(SyncError.fromCode('SOMETHING_ELSE'), SyncError.server);
  });

  test('a pass reports it instead of a generic failure', () async {
    final outcome = await engine.sync();

    expect(outcome.error, SyncError.cursorTooOld);
    expect(engine.needsReseed, isTrue);
  });

  test('pulling stops, because it can never succeed again', () async {
    // The server's pruned watermark only rises, so the rows this cursor wants
    // are gone for good. A till fires a pass on every local write; without the
    // latch that is a doomed round trip every few seconds on mobile data.
    await engine.sync();
    expect(transport.pullCalls, 1);

    await engine.sync();
    await engine.sync();

    expect(transport.pullCalls, 1);
  });

  test('pushing keeps working, so sales are not stranded here', () async {
    // Only receiving is broken. A phone that cannot catch up must still hand
    // over what it rang, or a stale device becomes a lost day of takings.
    await seedUnpushedLocalRow('p1', 1);
    await engine.sync();
    expect(transport.pushCalls, 1);

    // And it is still pushing on a later pass, after the pull latch is set.
    await seedUnpushedLocalRow('p2', 2);
    final second = await engine.sync();

    expect(transport.pushCalls, 2);
    expect(second.pushed, 1);
    // Reported as a failure all the same — the phone IS out of step, and a
    // pass that pushed but could not pull is not a clean sync.
    expect(second.error, SyncError.cursorTooOld);
  });

  test('every later pass still says the phone is behind', () async {
    // Latching must not make the screen go quiet. "Up to date" because we
    // stopped asking is the same silence this replaced.
    await engine.sync();
    final second = await engine.sync();

    expect(second.error, SyncError.cursorTooOld);
  });

  test('adopting a fresh snapshot clears the block', () async {
    // Re-seeding is the recovery the error demands; a re-seeded phone that
    // still refused to pull would be stuck holding a cursor that is now valid.
    await engine.sync();
    expect(engine.needsReseed, isTrue);

    await engine.adoptBootstrap(5000);

    expect(engine.needsReseed, isFalse);
    await engine.sync();
    expect(transport.pullCalls, 2); // it tried again
  });
}
