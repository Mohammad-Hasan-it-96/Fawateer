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

  /// Set once the server has told us our pull cursor is below its pruned
  /// watermark (`CURSOR_TOO_OLD`). Pull is skipped while it holds, because the
  /// rows it wants no longer exist and the server's watermark only rises — the
  /// request cannot start succeeding. A busy till fires a pass on every local
  /// write, so without this the shop pays for a doomed round trip every few
  /// seconds on mobile data.
  ///
  /// **Push is deliberately unaffected.** Only receiving is broken; the sales
  /// rung on this phone still reach the rest of the shop while it waits to be
  /// re-linked, and stranding them would turn a stale device into a lost day.
  ///
  /// **In memory, not persisted.** A restart costs one wasted request and buys
  /// self-healing: if the window is ever widened server-side, the phone
  /// recovers on its own instead of staying blocked on a fact that has expired.
  bool _pullBlocked = false;

  /// True when this device can no longer catch up and needs re-seeding from a
  /// fresh snapshot — the state the sync screen explains to the shopkeeper.
  bool get needsReseed => _pullBlocked;

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
      //
      // The server's own words are carried out alongside the typed error. Most
      // refusals have no typed code and collapse onto `SyncError.server`, whose
      // copy is "something went wrong, try again" — correct for a shopkeeper and
      // useless for anyone diagnosing a shop that cannot sync. See
      // [SyncOutcome.errorDetail].
      return outcome.copyWith(
        error: e.isOffline ? SyncError.offline : SyncError.fromCode(e.code),
        errorDetail: e.code == null ? e.message : '${e.code}: ${e.message}',
      );
    } catch (e) {
      return outcome.copyWith(
          error: SyncError.server, errorDetail: e.toString());
    }
  }

  Future<SyncOutcome> _push(SyncOutcome outcome) async {
    var pushed = 0;
    var rejected = 0;
    var conflicts = 0;

    // Loop so a large backlog drains over several batches in one pass, but stop
    // at the first batch the server does not fully take — pushing on past a
    // rejection would advance the watermark over rows that never landed.
    while (true) {
      final watermark = await _state.pushWatermark();
      final changes = await _dao.collectSince(
        watermark,
        originDevice: _clock.nodeId,
        limit: batchSize,
      );
      if (changes.isEmpty) break;

      final result = await _transport.push(changes);
      // A conflicted row still landed, so it counts as pushed for the
      // watermark and for "did anything move" — but it is also counted
      // separately, because "12 sent" and "12 sent, 2 of which disagreed with
      // the other phone" are different answers and the second one is true.
      pushed += result.accepted.length + result.conflicts.length;
      rejected += result.rejected.length;
      conflicts += result.conflicts.length;

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

    return outcome.copyWith(
        pushed: pushed, rejected: rejected, conflicts: conflicts);
  }

  Future<SyncOutcome> _pull(SyncOutcome outcome) async {
    // Still reported as an error every pass, not quietly skipped: the phone IS
    // out of date, and a screen that goes back to saying "up to date" because
    // we stopped asking would be the same silence this replaced.
    if (_pullBlocked) {
      return outcome.copyWith(error: SyncError.cursorTooOld);
    }
    var applied = 0;

    for (var page = 0; page < maxPullPages; page++) {
      final since = await _state.pullCursor();
      final PullPage result;
      try {
        result = await _transport.pull(since: since, limit: batchSize);
      } on SyncApiException catch (e) {
        // Latch here rather than in `_run`'s catch-all, so the flag is set only
        // by an actual pull refusal — a push that failed with the same code
        // (it cannot today) must not disable pulling.
        if (SyncError.fromCode(e.code) == SyncError.cursorTooOld) {
          _pullBlocked = true;
        }
        rethrow;
      }

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

  /// Adopt the pull position handed over at enrollment, for the case where no
  /// snapshot came with it.
  ///
  /// The cursor **must** come from the owner's local pull position captured
  /// before the snapshot was taken — not from the server's current head. Taking
  /// it after would skip every change committed between the snapshot and the
  /// handoff; we got this wrong once and the backend had adopted it verbatim
  /// (see `docs/backend-replies/2026-07-29-fawateer-response.txt` §1).
  ///
  /// **Only the cursor.** An earlier draft also pushed the watermark up to
  /// [SyncDao.highestLocalHlc], reasoning that the snapshot's rows came from the
  /// server and need not go back. That is right for a restored snapshot — and it
  /// is handled inside the snapshot itself by [SnapshotSeeder], which is the only
  /// place it can be handled at all — but catastrophic here: a device enrolling
  /// *without* a snapshot holds local rows that have never been anywhere, and
  /// moving the watermark past them means they are never pushed. The shop's first
  /// device establishing a business is exactly that case, so it would have
  /// silently declined to upload the entire shop.
  Future<void> adoptBootstrap(int cursor) async {
    // A fresh snapshot is exactly the recovery `CURSOR_TOO_OLD` demands, so
    // adopting one clears the block. Without this a re-seeded phone would sit
    // there refusing to pull, holding a cursor that is now perfectly valid.
    _pullBlocked = false;
    await _state.resetPullCursor(cursor);
  }
}
