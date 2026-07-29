import '../database/daos/settings_dao.dart';
import 'hlc.dart';

/// Key under which the clock's position survives a restart.
const String kSyncClockKey = 'sync_hlc';

/// One local event's sync bookkeeping: *when* it happened on the logical clock,
/// and *which device* it happened on.
///
/// A tiny value object rather than two loose `String`s because the two are
/// always written together and are trivially transposable at a call site — the
/// same "make it a compile error, not a runtime surprise" reasoning behind
/// passing typed columns to `addSyncMeta` in the v16 migration.
class SyncStamp {
  /// Packed [Hlc] — goes into `updatedAt` (and `deletedAt` for a tombstone).
  final String hlc;

  /// This device's node id — goes into `originDevice`.
  final String device;

  const SyncStamp({required this.hlc, required this.device});

  @override
  String toString() => 'SyncStamp($hlc)';
}

/// Issues the [Hlc] stamps that every replicated write carries.
///
/// [Hlc] itself is pure and knows nothing about storage; this is the piece that
/// owns "what time is it *here*, now" — it holds the device's current clock
/// position, advances it, and persists it.
///
/// **Why it persists.** The HLC's guarantee is that it never issues a value
/// below one it has already issued. Held only in memory, that guarantee ends at
/// process exit: a phone whose clock is dragged backwards (or that was ahead of
/// wall-clock because it merged a fast peer) would restart, read a lower
/// physical time, and start re-issuing stamps it has already used. Two different
/// edits would then carry the same position and last-write-wins would have no
/// answer. One key-value row per stamp is a small price for that.
///
/// Deletes are rare, so the write cost is negligible today; when ordinary edits
/// start stamping too, this is the thing to batch — not to drop.
class SyncClock {
  SyncClock(this._settings, {int Function()? now})
      : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final SettingsDao _settings;
  final int Function() _now;

  String _nodeId = '';
  Hlc? _current;

  /// This device's node id, or `''` before [load].
  String get nodeId => _nodeId;

  /// Whether [load] has run. A stamp taken before that would carry an empty
  /// node id, which [Hlc.unpack] rejects as malformed — so callers that could
  /// run pre-startup should check.
  bool get isReady => _nodeId.isNotEmpty;

  /// Adopt [nodeId] and restore the persisted clock position.
  ///
  /// Called once at startup, after the device id resolves. Safe to call again
  /// (a device id can change after a factory reset); the clock keeps its
  /// position and only swaps identity.
  Future<void> load(String nodeId) async {
    _nodeId = nodeId;
    final stored = Hlc.unpack(await _settings.getValue(kSyncClockKey));
    // The stored stamp's own node id is deliberately discarded. It is normally
    // ours, but after a factory reset (or a restore of another device's backup —
    // Plan 001 copies the whole SQLite file, this row included) it belongs to a
    // *different* device. Keeping its physical position preserves monotonicity;
    // keeping its identity would make us stamp rows as that device and corrupt
    // both the audit trail and the HLC tie-break.
    _current = stored == null
        ? Hlc.zero(nodeId)
        : Hlc(millis: stored.millis, counter: stored.counter, nodeId: nodeId);
  }

  /// Advance the clock and return the stamp for one local event.
  ///
  /// The in-memory advance happens *before* the await, so two concurrent
  /// callers can never be handed the same position — each sees the other's
  /// increment. Only the persistence is asynchronous.
  Future<SyncStamp> stamp() async {
    final next = (_current ?? Hlc.zero(_nodeId)).localEvent(_now());
    _current = next;
    final packed = next.pack();
    await _settings.setValue(kSyncClockKey, packed);
    return SyncStamp(hlc: packed, device: _nodeId);
  }

  /// Fold a timestamp seen from another device into this clock, so anything we
  /// stamp afterwards sorts *after* what we have already observed.
  ///
  /// Unused until the sync engine lands — it is here because it is the other
  /// half of [Hlc.receive]'s contract, and a clock that only ever advances
  /// locally silently loses the cross-device happened-before guarantee that is
  /// the entire reason this is an HLC and not a wall clock.
  Future<void> observe(String packedRemote) async {
    final remote = Hlc.unpack(packedRemote);
    if (remote == null) return;
    final merged = (_current ?? Hlc.zero(_nodeId)).receive(remote, _now());
    _current = merged;
    await _settings.setValue(kSyncClockKey, merged.pack());
  }
}
