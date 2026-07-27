/// Hybrid Logical Clock — the ordering primitive for multi-device sync
/// (Plan 002, Phase 0).
///
/// ## Why not just use `DateTime.now()`
///
/// Last-write-wins needs to answer "which edit is newer". Wall-clock time
/// cannot answer it safely here: this app **already distrusts device clocks**
/// (`LicenseGuards` carries a 48-hour rollback check precisely because shop
/// phones have wrong times — flat batteries, manual "fixes", no NTP). A cashier
/// whose phone is a day fast would win every conflict forever, and one whose
/// phone is a day slow would lose edits they made seconds ago.
///
/// An HLC keeps wall-clock *readability* (the value is still roughly "when")
/// while guaranteeing the one property ordering actually needs: **if event A
/// happened-before event B on any device, then A < B**. It does that by
/// carrying a counter that breaks ties and by never moving backwards.
///
/// ## Why not a plain Lamport counter
///
/// A pure logical counter would order correctly but lose all relation to real
/// time, so a human could never read a row's `updatedAt` and a support call
/// ("what changed this morning?") becomes unanswerable. The hybrid keeps both.
///
/// ## The other clock
///
/// This is **not** the sync cursor. The server assigns a separate monotonic
/// sequence when it accepts a change, and that is what drives pagination
/// ("what haven't I seen"). Conflating the two is the bug where a device that
/// was offline for three days pushes stale edits that beat fresher ones,
/// because arrival order is not authorship order. See
/// `docs/evotech-core-multi-device-prompt.txt` §3 D5.
library;

import 'package:equatable/equatable.dart';

/// How far ahead of our own clock a *remote* timestamp may be before we stop
/// trusting it (see [Hlc.receive]).
///
/// A device whose clock is wildly fast would otherwise win every conflict
/// forever — its rows would carry timestamps no honest device can reach. One
/// hour is comfortably more than real-world skew between phones that are
/// roughly time-synced, and far less than the tampering cases the licence
/// guard was written for.
const Duration kMaxClockDrift = Duration(hours: 1);

/// Widths used by [Hlc.pack]. Fixed so the packed form sorts **lexicographically
/// in the same order as [compareTo]** — that is what lets SQL do
/// `WHERE updated_at > ?` and `ORDER BY updated_at` with no special collation.
const int _millisDigits = 15; // year ~33658 before this overflows
const int _counterDigits = 5;

/// Largest counter value before we borrow a millisecond (see [_advance]).
const int _maxCounter = 99999;

/// A single point on the hybrid clock: physical time, a tie-breaking counter,
/// and the device that stamped it.
class Hlc extends Equatable implements Comparable<Hlc> {
  /// Physical time component, ms since epoch. May run slightly *ahead* of the
  /// device's real clock — that is the "hybrid" part, and is how causality
  /// survives a slow clock.
  final int millis;

  /// Breaks ties within the same millisecond, and absorbs the case where the
  /// physical clock stands still or moves backwards.
  final int counter;

  /// The device that produced this timestamp. Also the final tie-break, so two
  /// devices stamping the identical millisecond+counter still get a **total,
  /// deterministic** order — every device resolves such a tie the same way,
  /// which is what stops them diverging.
  final String nodeId;

  const Hlc({
    required this.millis,
    required this.counter,
    required this.nodeId,
  });

  /// The clock's starting point on a device that has never stamped anything.
  factory Hlc.zero(String nodeId) =>
      Hlc(millis: 0, counter: 0, nodeId: nodeId);

  /// Stamp a **local** event.
  ///
  /// [physicalNow] is injected rather than read here so this stays pure and
  /// testable — the same reason `LicenseGuards` takes its clock as a parameter.
  Hlc localEvent(int physicalNow) {
    // Never go backwards: if the device clock has slipped behind what we've
    // already issued, keep our own time and just advance the counter.
    if (physicalNow <= millis) return _advance(millis, counter + 1, nodeId);
    return Hlc(millis: physicalNow, counter: 0, nodeId: nodeId);
  }

  /// Merge a timestamp that arrived from another device.
  ///
  /// Returns this device's new clock position, which must be at least as late
  /// as anything it has now seen — that is what makes "happened-before" hold
  /// across devices rather than only within one.
  ///
  /// A [remote] more than [kMaxClockDrift] ahead of [physicalNow] is **clamped,
  /// not rejected**. Rejecting would be the textbook answer, but here it would
  /// mean discarding a real shop's sale because a phone's clock was wrong —
  /// data loss to protect ordering, which is the wrong trade for a POS. Clamping
  /// bounds how far a bad clock can poison the ordering while keeping the data.
  Hlc receive(Hlc remote, int physicalNow) {
    final ceiling = physicalNow + kMaxClockDrift.inMilliseconds;
    final remoteMillis =
        remote.millis > ceiling ? ceiling : remote.millis;

    final maxMillis = [millis, remoteMillis, physicalNow]
        .reduce((a, b) => a > b ? a : b);

    // Whichever inputs are tied at the newest millisecond must have their
    // counters considered, so a merge never produces a value that collides with
    // one we've already issued or already seen.
    if (maxMillis == millis && maxMillis == remoteMillis) {
      final c = counter > remote.counter ? counter : remote.counter;
      return _advance(maxMillis, c + 1, nodeId);
    }
    if (maxMillis == millis) return _advance(maxMillis, counter + 1, nodeId);
    if (maxMillis == remoteMillis) {
      return _advance(maxMillis, remote.counter + 1, nodeId);
    }
    return Hlc(millis: maxMillis, counter: 0, nodeId: nodeId);
  }

  /// Roll a saturated counter into the next millisecond rather than letting it
  /// overflow its fixed width in [pack] (which would break sort order — the one
  /// property everything else depends on).
  static Hlc _advance(int millis, int counter, String nodeId) =>
      counter > _maxCounter
          ? Hlc(millis: millis + 1, counter: 0, nodeId: nodeId)
          : Hlc(millis: millis, counter: counter, nodeId: nodeId);

  /// The stored form: fixed-width, so **string order == clock order**.
  ///
  /// Zero-padded decimal rather than hex or ISO-8601 purely because it is the
  /// least surprising thing to see in a SQLite browser during a support call.
  String pack() => '${millis.toString().padLeft(_millisDigits, '0')}'
      '-${counter.toString().padLeft(_counterDigits, '0')}'
      '-$nodeId';

  /// Parse [pack]ed text. Returns `null` for anything malformed — a corrupt or
  /// legacy value must degrade to "unknown", never crash a sync merge or a
  /// screen that is just trying to show a row.
  static Hlc? unpack(String? packed) {
    if (packed == null || packed.isEmpty) return null;
    final first = packed.indexOf('-');
    if (first < 0) return null;
    final second = packed.indexOf('-', first + 1);
    if (second < 0) return null;

    final millis = int.tryParse(packed.substring(0, first));
    final counter = int.tryParse(packed.substring(first + 1, second));
    final node = packed.substring(second + 1);
    if (millis == null || counter == null || node.isEmpty) return null;
    if (millis < 0 || counter < 0) return null;
    return Hlc(millis: millis, counter: counter, nodeId: node);
  }

  /// Wall-clock reading of this stamp, for display only. Never order by this —
  /// it drops the counter, so two events in the same millisecond compare equal.
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(millis);

  @override
  int compareTo(Hlc other) {
    final byMillis = millis.compareTo(other.millis);
    if (byMillis != 0) return byMillis;
    final byCounter = counter.compareTo(other.counter);
    if (byCounter != 0) return byCounter;
    return nodeId.compareTo(other.nodeId);
  }

  bool operator >(Hlc other) => compareTo(other) > 0;
  bool operator <(Hlc other) => compareTo(other) < 0;
  bool operator >=(Hlc other) => compareTo(other) >= 0;
  bool operator <=(Hlc other) => compareTo(other) <= 0;

  @override
  List<Object?> get props => [millis, counter, nodeId];

  @override
  String toString() => 'Hlc(${pack()})';
}
