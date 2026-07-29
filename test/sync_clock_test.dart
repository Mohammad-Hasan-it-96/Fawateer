// The stamping service behind every tombstone (Plan 002, Phase 0).
//
// `Hlc` itself is pure and covered by its own arithmetic; what is tested here is
// the part that can lose data: whether the clock still refuses to repeat itself
// once a real device clock misbehaves, and whether it survives a restart.
import 'package:billing_app/core/database/daos/settings_dao.dart';
import 'package:billing_app/core/sync/hlc.dart';
import 'package:billing_app/core/sync/sync_clock.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the key-value table. `noSuchMethod` covers the rest of the DAO
/// surface, which this never touches — same spirit as the hand-written fake
/// repositories the BLoC tests use, so no Drift or native SQLite is involved.
class _FakeSettingsDao implements SettingsDao {
  final Map<String, String> store = {};

  @override
  Future<String?> getValue(String key) async => store[key];

  @override
  Future<void> setValue(String key, String value) async {
    store[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not needed');
}

void main() {
  const node = 'abc123def4567890';

  group('SyncClock', () {
    test('is not ready until loaded, then carries the node id', () async {
      final clock = SyncClock(_FakeSettingsDao(), now: () => 1000);
      expect(clock.isReady, isFalse);
      expect(clock.nodeId, '');

      await clock.load(node);
      expect(clock.isReady, isTrue);
      expect(clock.nodeId, node);
    });

    test('stamps carry this device and are readable as a time', () async {
      final clock = SyncClock(_FakeSettingsDao(), now: () => 1785312000000);
      await clock.load(node);

      final stamp = await clock.stamp();
      expect(stamp.device, node);
      final parsed = Hlc.unpack(stamp.hlc);
      expect(parsed, isNotNull);
      expect(parsed!.millis, 1785312000000);
      expect(parsed.nodeId, node);
    });

    test('a frozen device clock still yields strictly increasing stamps',
        () async {
      // Two deletes inside the same millisecond is not hypothetical — a
      // "delete all" loop does exactly this. If both got the same stamp,
      // last-write-wins would have no answer for which one won.
      final clock = SyncClock(_FakeSettingsDao(), now: () => 5000);
      await clock.load(node);

      final a = Hlc.unpack((await clock.stamp()).hlc)!;
      final b = Hlc.unpack((await clock.stamp()).hlc)!;
      final c = Hlc.unpack((await clock.stamp()).hlc)!;

      expect(b > a, isTrue);
      expect(c > b, isTrue);
      expect(a.millis, b.millis, reason: 'the counter is what advanced');
      expect(b.counter, a.counter + 1);
    });

    test('a device clock dragged backwards cannot reissue a used position',
        () async {
      // The licence guard exists because shop phones have wrong clocks; the
      // same reality applies here. A stamp issued at T must stay below every
      // stamp issued after it, even if the phone now says T - 1 day.
      var now = 2000000;
      final clock = SyncClock(_FakeSettingsDao(), now: () => now);
      await clock.load(node);

      final before = Hlc.unpack((await clock.stamp()).hlc)!;
      now = 1000; // battery died, clock reset
      final after = Hlc.unpack((await clock.stamp()).hlc)!;

      expect(after > before, isTrue,
          reason: 'a rolled-back clock must not rewind the logical clock');
      expect(after.millis, before.millis);
    });

    test('the position survives a restart', () async {
      // Held only in memory, the whole guarantee ends at process exit: the
      // phone restarts, reads a lower physical time, and starts handing out
      // stamps it has already used.
      final store = _FakeSettingsDao();
      var now = 9000000;
      final first = SyncClock(store, now: () => now);
      await first.load(node);
      final last = Hlc.unpack((await first.stamp()).hlc)!;

      now = 1000; // reboot with a wrong clock
      final second = SyncClock(store, now: () => now);
      await second.load(node);
      final resumed = Hlc.unpack((await second.stamp()).hlc)!;

      expect(resumed > last, isTrue);
      expect(store.store.containsKey(kSyncClockKey), isTrue);
    });

    test('a restored stamp from another device keeps its time, not its identity',
        () async {
      // Plan 001 restores the whole SQLite file, this key-value row included —
      // so the persisted position can genuinely belong to a different handset.
      // Adopting its node id would make this device stamp rows as that one and
      // corrupt both the audit trail and the HLC's final tie-break.
      final store = _FakeSettingsDao();
      store.store[kSyncClockKey] =
          const Hlc(millis: 7000000, counter: 3, nodeId: 'someoneelses123')
              .pack();

      final clock = SyncClock(store, now: () => 1000);
      await clock.load(node);
      final stamp = Hlc.unpack((await clock.stamp()).hlc)!;

      expect(stamp.nodeId, node, reason: 'we never stamp as another device');
      expect(stamp.millis, 7000000, reason: 'but we keep its position');
    });

    test('a corrupt stored value degrades to a fresh clock, never a crash',
        () async {
      final store = _FakeSettingsDao();
      store.store[kSyncClockKey] = 'not-an-hlc-at-all';

      final clock = SyncClock(store, now: () => 4242);
      await clock.load(node);
      final stamp = Hlc.unpack((await clock.stamp()).hlc)!;

      expect(stamp.millis, 4242);
      expect(stamp.nodeId, node);
    });

    test('observing a remote stamp pulls our clock past it', () async {
      // Without this, a row we edit right after receiving a newer remote edit
      // would carry an older stamp and lose the merge it should win.
      final clock = SyncClock(_FakeSettingsDao(), now: () => 6000000);
      await clock.load(node);

      const remote = Hlc(millis: 6000500, counter: 0, nodeId: 'otherdevice12345');
      await clock.observe(remote.pack());
      final mine = Hlc.unpack((await clock.stamp()).hlc)!;

      expect(mine > remote, isTrue);
    });

    test('a wildly-future remote stamp is clamped, not obeyed', () async {
      // A phone whose clock is set to 2030 would otherwise win every conflict
      // forever, because no honest device could ever reach its timestamps. The
      // remote is clamped rather than rejected: dropping it would discard a
      // real shop's data to protect ordering, which is the wrong trade for a
      // POS.
      const now = 6000000;
      final clock = SyncClock(_FakeSettingsDao(), now: () => now);
      await clock.load(node);

      const runaway =
          Hlc(millis: 99999999999, counter: 0, nodeId: 'fastdevice123456');
      await clock.observe(runaway.pack());
      final mine = Hlc.unpack((await clock.stamp()).hlc)!;

      expect(mine.millis, lessThanOrEqualTo(now + kMaxClockDrift.inMilliseconds),
          reason: 'a bad clock may not drag ours arbitrarily far forward');
      expect(mine < runaway, isTrue,
          reason: 'and it keeps winning until our own clock catches up — the '
              'bounded cost of not throwing its data away');
    });

    test('an unreadable remote stamp is ignored, not fatal', () async {
      final clock = SyncClock(_FakeSettingsDao(), now: () => 1000);
      await clock.load(node);
      final before = Hlc.unpack((await clock.stamp()).hlc)!;

      await clock.observe('');
      await clock.observe('garbage');
      final after = Hlc.unpack((await clock.stamp()).hlc)!;

      expect(after > before, isTrue);
    });
  });
}
