import 'package:billing_app/core/sync/hlc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the Hybrid Logical Clock (Plan 002 Phase 0).
///
/// Pure logic, no BLoC and no database — same bar as `num_input_test` and the
/// `LicenseGuards` tests. The clock is injected everywhere, so none of this
/// depends on the machine's real time.
void main() {
  const nodeA = 'device-a';
  const nodeB = 'device-b';

  // A fixed "now" so tests read as arithmetic rather than as timing.
  const t0 = 1800000000000; // some ms since epoch

  group('localEvent', () {
    test('takes the physical clock when it has moved forward', () {
      final clock = Hlc.zero(nodeA).localEvent(t0);
      expect(clock.millis, t0);
      expect(clock.counter, 0);
      expect(clock.nodeId, nodeA);
    });

    test('advances the counter when the physical clock has not moved', () {
      final first = Hlc.zero(nodeA).localEvent(t0);
      final second = first.localEvent(t0);
      final third = second.localEvent(t0);

      expect(second.millis, t0);
      expect(second.counter, 1);
      expect(third.counter, 2);
      // The whole point: same millisecond, still strictly increasing.
      expect(second > first, isTrue);
      expect(third > second, isTrue);
    });

    test('never moves backwards when the device clock slips back', () {
      final ahead = Hlc.zero(nodeA).localEvent(t0);
      // Phone's clock jumps back a full minute (battery pull, manual fix).
      final after = ahead.localEvent(t0 - 60000);

      expect(after.millis, t0, reason: 'must not adopt the earlier time');
      expect(after > ahead, isTrue, reason: 'must still be strictly newer');
    });

    test('rolls a saturated counter into the next millisecond', () {
      // Drive the counter to its ceiling without the physical clock moving.
      var clock = const Hlc(millis: t0, counter: 99999, nodeId: nodeA);
      clock = clock.localEvent(t0);

      expect(clock.millis, t0 + 1);
      expect(clock.counter, 0);
      // Sort order must survive the roll — this is why the roll exists.
      expect(clock > const Hlc(millis: t0, counter: 99999, nodeId: nodeA), isTrue);
    });
  });

  group('receive', () {
    test('adopts a newer remote time', () {
      final local = Hlc.zero(nodeA).localEvent(t0);
      const remote = Hlc(millis: t0 + 5000, counter: 0, nodeId: nodeB);

      final merged = local.receive(remote, t0);

      expect(merged.millis, t0 + 5000);
      expect(merged.nodeId, nodeA, reason: 'stays our own clock');
      expect(merged > remote, isTrue);
    });

    test('keeps local time when the remote is older', () {
      const local = Hlc(millis: t0, counter: 3, nodeId: nodeA);
      const remote = Hlc(millis: t0 - 10000, counter: 0, nodeId: nodeB);

      final merged = local.receive(remote, t0);

      expect(merged.millis, t0);
      expect(merged.counter, 4, reason: 'still advances past what we issued');
    });

    test('breaks a same-millisecond tie by taking the higher counter + 1', () {
      const local = Hlc(millis: t0, counter: 2, nodeId: nodeA);
      const remote = Hlc(millis: t0, counter: 7, nodeId: nodeB);

      final merged = local.receive(remote, t0);

      expect(merged.millis, t0);
      expect(merged.counter, 8);
      expect(merged > remote, isTrue);
      expect(merged > local, isTrue);
    });

    test('clamps a remote whose clock is absurdly far ahead', () {
      final local = Hlc.zero(nodeA).localEvent(t0);
      // A device a full year in the future would otherwise win every
      // last-write-wins comparison forever.
      final liar = Hlc(
          millis: t0 + const Duration(days: 365).inMilliseconds,
          counter: 0,
          nodeId: nodeB);

      final merged = local.receive(liar, t0);

      final ceiling = t0 + kMaxClockDrift.inMilliseconds;
      expect(merged.millis, lessThanOrEqualTo(ceiling));
      expect(merged.millis, greaterThan(t0),
          reason: 'clamped, not discarded — the row is still accepted');
    });

    test('tolerates ordinary skew without clamping', () {
      final local = Hlc.zero(nodeA).localEvent(t0);
      // Half a minute out is normal between two phones.
      const remote = Hlc(millis: t0 + 30000, counter: 0, nodeId: nodeB);

      final merged = local.receive(remote, t0);

      expect(merged.millis, t0 + 30000);
    });
  });

  group('causality across devices', () {
    test('an edit that happened-before another compares as earlier', () {
      // A stamps a change...
      final a1 = Hlc.zero(nodeA).localEvent(t0);
      // ...B receives it and immediately makes its own edit, on a phone whose
      // clock happens to be BEHIND A's. Wall-clock ordering would get this
      // wrong; the HLC must not.
      final b1 = Hlc.zero(nodeB).receive(a1, t0 - 5000);

      expect(b1 > a1, isTrue,
          reason: 'B edited after A, so B must win last-write-wins');
    });

    test('two devices stamping the same instant still get a total order', () {
      const a = Hlc(millis: t0, counter: 0, nodeId: nodeA);
      const b = Hlc(millis: t0, counter: 0, nodeId: nodeB);

      // Identical clock position — the node id decides, and every device
      // decides the same way, which is what stops them diverging.
      expect(a.compareTo(b), isNot(0));
      expect(a.compareTo(b) < 0, b.compareTo(a) > 0);
    });
  });

  group('pack / unpack', () {
    test('round-trips', () {
      const clock = Hlc(millis: t0, counter: 42, nodeId: nodeA);
      expect(Hlc.unpack(clock.pack()), clock);
    });

    test('string order matches clock order — SQL depends on this', () {
      const samples = <Hlc>[
        Hlc(millis: t0, counter: 0, nodeId: nodeA),
        Hlc(millis: t0, counter: 1, nodeId: nodeA),
        Hlc(millis: t0, counter: 12, nodeId: nodeA),
        Hlc(millis: t0 + 1, counter: 0, nodeId: nodeA),
        Hlc(millis: t0 + 1000, counter: 0, nodeId: nodeA),
        Hlc(millis: t0 * 2, counter: 0, nodeId: nodeA),
      ];

      final byClock = [...samples]..sort();
      final byString = [...samples]
        ..sort((x, y) => x.pack().compareTo(y.pack()));

      expect(byString, byClock,
          reason: 'lexicographic order must equal chronological order');
    });

    test('a node id containing a hyphen still parses', () {
      // Device ids are SHA-256 hex today, but nothing guarantees that forever.
      const clock = Hlc(millis: t0, counter: 1, nodeId: 'a-b-c');
      expect(Hlc.unpack(clock.pack())?.nodeId, 'a-b-c');
    });

    test('malformed input degrades to null rather than throwing', () {
      for (final bad in [
        null,
        '',
        'nonsense',
        '123',
        '123-456',
        'abc-def-node',
        '-1--1-node',
        '000-000-', // empty node
      ]) {
        expect(Hlc.unpack(bad), isNull, reason: 'input: $bad');
      }
    });
  });
}
