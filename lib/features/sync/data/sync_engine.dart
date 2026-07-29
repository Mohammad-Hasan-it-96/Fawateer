import 'dart:async';

import '../../../core/database/daos/sync_dao.dart';
import '../../../core/network/sync_api_client.dart';
import '../../../core/sync/sync_clock.dart';
import '../domain/entities/sync_outcome.dart';
import '../domain/sync_error.dart';
import '../domain/sync_transport.dart';
import 'sync_state_store.dart';

/// Drives one sync pass: push what changed here, then pull what changed
/// elsewhere (Plan 002, Phase 1).
///
/// **Push first, always.** A pull that ran first would apply a remote edit over
/// a local row whose own change has not left the device yet; the local change
/// is still queued and would be pushed afterwards, so it survives — but for the
/// window in between the shopkeeper watches their edit vanish and come back.
/// Pushing first also means a device that is about to be revoked, or whose
/// battery is about to die, has already handed over its sales.
///
/// The engine is **serialised**: a second call while one is running returns the
/// in-flight pass rather than starting another. Two concurrent passes would
/// both read the same watermark, push the same rows (harmless — the idempotency
/// key absorbs it) and then race to advance the cursor (not harmless).
class SyncEngine {
  final SyncDao _dao;
  final SyncTransport _transport;
  final SyncStateStore _state;
  final SyncClock _clock;
  final DateTime Function() _now;

  /// How many local changes go in one push, and how many rows a pull page asks
  /// for. Bounded so a device that has been offline for a week catches up in
  /// several short requests rather than one that times out on a shop's 3G.
  final int batchSize;

  /// Ceiling on pull pages per pass. A pass that keeps finding `has_more`
  /// eventually yields, so a backlog cannot hold the app hostage — the next
  /// tick resumes from the cursor.
  final int maxPullPages;

  Future<SyncOutcome>? _inFlight;

  SyncEngine({
    required SyncDao dao,
    required SyncTransport transport,
    required SyncStateStore state,
    required SyncClock clock,
    DateTime Function()? now,
    this.batchSize = 200,
    this.maxPullPages = 20,
  })  : _dao = dao,
        _transport = transport,
        _state = state,
        _clock = clock,
        _now = now ?? DateTime.now;

  /// True while a pass is running — for a spinner, and for callers that would
  /// rather skip than queue.
  bool get isSyncing => _inFlight != null;

  /// Run one pass, or join the one already running.
  Future<SyncOutcome> sync() {
    final running = _inFlight;
    if (running != null) return running;
    final pass = _run().whenComplete(() => _inFlight = null);
    _inFlight = pass;
    return pass;
  }

  Future<SyncOutcome> _run() async {
    var outcome = const SyncOutcome();
    try {
      outcome = await _push(outcome);
      outcome = await _pull(outcome);
      await _state.setLastSyncAt(_now());
      return outcome;
    } on SyncApiException catch (e) {
      // Partial work is kept: whatever was pushed before the failure is already
      // on the server and its watermark has advanced.
      return outcome.copyWith(
          error: e.isOffline ? SyncError.offline : SyncError.fromCode(e.code));
    } catch (_) {
      return outcome.copyWith(error: SyncError.server);
    }
  }

  Future<SyncOutcome> _push(SyncOutcome outcome) async {
    var pushed = 0;
    var rejected = 0;

    // Loop so a large backlog drains over several batches in one pass, but stop
    // at the first batch the server does not fully take — pushing on past a
    // rejection would advance the watermark over rows that never landed.
    while (true) {
      final watermark = await _state.pushWatermark();
      final changes = await _dao.collectSince(watermark, limit: batchSize);
      if (changes.isEmpty) break;

      final result = await _transport.push(changes);
      pushed += result.accepted.length + result.conflicts.length;
      rejected += result.rejected.length;

      // Advance only as far as the last *contiguous* accepted change. The list
      // is in authorship order, so stopping at the first row the server did not
      // take leaves it — and everything after it — to be retried. Advancing to
      // the highest accepted HLC instead would step over the rejected row and
      // strand it permanently, which is how a single bad row silently costs a
      // shop a day of sales.
      var advanceTo = watermark;
      for (final change in changes) {
        final settled = result.accepted.contains(change.rowUuid) ||
            result.conflicts.contains(change.rowUuid);
        if (!settled) break;
        advanceTo = change.authoredHlc;
      }
      if (advanceTo != watermark) await _state.setPushWatermark(advanceTo);

      if (result.rejected.isNotEmpty) break;
      if (changes.length < batchSize) break;
      if (advanceTo == watermark) break; // no progress — do not spin
    }

    return outcome.copyWith(pushed: pushed, rejected: rejected);
  }

  Future<SyncOutcome> _pull(SyncOutcome outcome) async {
    var applied = 0;

    for (var page = 0; page < maxPullPages; page++) {
      final since = await _state.pullCursor();
      final result = await _transport.pull(since: since, limit: batchSize);

      if (result.changes.isNotEmpty) {
        // Fold every remote stamp into our clock BEFORE applying, so anything
        // we author next sorts after what we have just seen. Skipping this
        // silently loses the cross-device happened-before guarantee that is the
        // entire reason updated_at is an HLC and not a wall clock.
        for (final change in result.changes) {
          await _clock.observe(change.authoredHlc);
        }
        applied += await _dao.applyChanges(result.changes);
      }

      // The cursor advances on the server's word even when nothing applied —
      // a page of pure echoes still means we have seen those sequences, and not
      // advancing would re-read them forever.
      await _state.setPullCursor(result.nextCursor);

      if (!result.hasMore) break;
    }

    return outcome.copyWith(pulled: applied);
  }

  /// Adopt the seed handed over at enrollment: start pulling from the owner's
  /// own cursor, and treat everything the snapshot brought as already pushed.
  ///
  /// The cursor **must** come from the owner's local pull position captured
  /// before the snapshot was taken — not from the server's current head. Taking
  /// it after would skip every change committed between the snapshot and the
  /// handoff; we got this wrong once and the backend had adopted it verbatim
  /// (see `docs/backend-replies/2026-07-29-fawateer-response.txt` §1).
  Future<void> adoptBootstrap(int cursor) async {
    await _state.resetPullCursor(cursor);
    // The snapshot's rows arrive carrying the stamps they already had. Pushing
    // them straight back would be a pointless round trip of data the server
    // demonstrably has — it is where they came from.
    await _state.setPushWatermark(await _dao.highestLocalHlc());
  }
}
