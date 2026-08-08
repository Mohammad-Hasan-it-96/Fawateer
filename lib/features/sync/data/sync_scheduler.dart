import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../core/database/daos/sync_dao.dart';
import '../domain/entities/sync_outcome.dart';
import '../domain/sync_error.dart';
import 'sync_credential_store.dart';
import 'sync_engine.dart';

/// Decides *when* a sync pass runs (Plan 002, Phase 1). `SyncEngine` decides
/// what a pass does; this owns the triggers.
///
/// **Foreground-triggered by design**, exactly like `AutoBackupService` and for
/// the same reasons: no `WorkManager`, no background service. Android's
/// background limits, battery policy and OEM task-killers make a real scheduler
/// a large support surface, and the tills in question are open on the counter
/// all day. What that costs is honest and worth stating — a till that is closed
/// does not sync, so the other till sees its sales when it is next opened.
///
/// **Inert until the device is enrolled.** A single-device shop — which is most
/// of them — has no seat token, so every trigger short-circuits before it
/// touches the database or the network. The feature costs such a shop nothing.
class SyncScheduler with WidgetsBindingObserver {
  SyncScheduler({
    required SyncEngine engine,
    required SyncCredentialStore credentials,
    required SyncDao dao,
    this.interval = const Duration(minutes: 5),
    this.debounce = const Duration(seconds: 3),
  })  : _engine = engine,
        _credentials = credentials,
        _dao = dao;

  final SyncEngine _engine;
  final SyncCredentialStore _credentials;
  final SyncDao _dao;

  /// Backstop cadence while the app is open. Deliberately unhurried: the
  /// local-change trigger already covers "a sale just happened", so this only
  /// has to catch changes made on the *other* till when no FCM doorbell
  /// arrived. Tighter would mean a request every minute on a shop's mobile data
  /// for, most of the time, nothing.
  final Duration interval;

  /// How long to wait after a local write before pushing.
  ///
  /// A sale writes an invoice, its lines, a stock movement and a cashbox entry
  /// in one transaction and the ticker fires for each; without a debounce that
  /// is four passes for one sale. Long enough to coalesce a burst, short enough
  /// that the other till sees the sale while the customer is still at the
  /// counter.
  final Duration debounce;

  Timer? _periodic;
  Timer? _debounce;
  StreamSubscription<void>? _changes;
  bool _started = false;

  /// A doorbell rang while a pass was already running.
  ///
  /// `SyncEngine.sync()` *joins* an in-flight pass rather than starting a second
  /// one, which is right for every other trigger and wrong for this one: a pass
  /// that has already read its cursor cannot see the change the doorbell is
  /// announcing, so joining it means the ring accomplished nothing and the other
  /// till's sale waits out the 5-minute timer — the exact delay the doorbell
  /// exists to remove. Bounded to a single follow-up: a ring during the
  /// follow-up is dropped, so a busy shop cannot chain passes indefinitely.
  bool _doorbellPending = false;

  /// The last pass's result, for a status UI. A [ValueListenable] rather than a
  /// BLoC because there is no state machine here — every consumer wants the
  /// same single latest value.
  final ValueNotifier<SyncOutcome?> lastOutcome = ValueNotifier(null);

  /// True while a pass is in flight (for a spinner).
  final ValueNotifier<bool> isSyncing = ValueNotifier(false);

  /// Begin listening. Idempotent — `main()` and a settings screen may both call
  /// it.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addObserver(this);
    _periodic = Timer.periodic(interval, (_) => _trigger(SyncTrigger.periodic));
    _changes = _dao.watchLocalChanges().listen((_) => _onLocalChange());

    await _trigger(SyncTrigger.launch);
  }

  void dispose() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _periodic?.cancel();
    _debounce?.cancel();
    _changes?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android keeps this app alive for days — a shop that never swipe-kills it
    // would otherwise only ever sync on the periodic tick. Resume is the moment
    // the shopkeeper is actually looking at the screen and expects it to be
    // current.
    if (state == AppLifecycleState.resumed) _trigger(SyncTrigger.resume);
  }

  /// A push notification told us the server has something for us. The doorbell
  /// carries no data — it only says "come and look" — so the pass is an
  /// ordinary one.
  void onRemoteChange() => _trigger(SyncTrigger.doorbell);

  void _onLocalChange() {
    _debounce?.cancel();
    _debounce = Timer(debounce, () => _trigger(SyncTrigger.localChange));
  }

  /// Run a pass now, bypassing the debounce — for a pull-to-refresh or an
  /// explicit "Sync now" button. Unlike the automatic triggers this returns the
  /// outcome, because a user who asked deserves an answer.
  Future<SyncOutcome?> syncNow() => _trigger(SyncTrigger.manual);

  Future<SyncOutcome?> _trigger(SyncTrigger trigger) async {
    if (!_started && trigger != SyncTrigger.manual) return null;

    // Everything is inside the try, including the credential read. A trigger
    // must never throw into a Timer callback or a lifecycle handler — an
    // unhandled error there takes down the zone, and this is a background
    // nicety, not something worth crashing a till over. Most triggers are
    // fire-and-forget, so there is nobody to catch it either.
    try {
      // The gate that keeps this free for single-device shops.
      final session = await _credentials.load();
      if (session == null) return null;

      // Deferred rather than joined — see [_doorbellPending]. Checked after the
      // seat gate so an unenrolled device never arms a follow-up.
      if (trigger == SyncTrigger.doorbell && _engine.isSyncing) {
        _doorbellPending = true;
        return null;
      }

      isSyncing.value = true;
      // `SyncEngine.sync()` joins an in-flight pass rather than starting a
      // second, so overlapping triggers (resume landing on a timer tick) cost
      // nothing.
      var outcome = await _engine.sync();
      if (_doorbellPending) {
        // Cleared *before* the follow-up, so a ring arriving during it is
        // dropped rather than arming a third pass.
        _doorbellPending = false;
        outcome = await _engine.sync();
      }
      lastOutcome.value = outcome;
      if (outcome.error == SyncError.deviceRevoked) await _onRevoked();
      return outcome;
    } catch (_) {
      // The engine already converts failures into a SyncOutcome; this catches
      // only what escapes it.
      return null;
    } finally {
      isSyncing.value = false;
    }
  }

  /// The owner revoked this device's seat. The server has already nulled the
  /// credential, so every further call would fail identically — drop it locally
  /// and let the scheduler go inert, exactly as it is for a shop that never
  /// enrolled.
  ///
  /// **Nothing local is deleted, and nothing can be.** The books stay on this
  /// phone in full (2026-07-29 R2); what stops is syncing, and — once the next
  /// licence check lands, bounded by the existing 7-day offline grace — selling.
  /// That is the ONE place the sync and licensing credentials are coupled, and
  /// it is the server's half, not ours.
  ///
  /// Unpushed local sales are stranded by this, which is unavoidable rather than
  /// chosen: the token they would have been pushed with is already dead. Only
  /// the explicit `DEVICE_REVOKED` code gets here — a bare 401 maps to
  /// `SyncError.server` and is retried, so a transient auth blip cannot silently
  /// unlink a working till.
  Future<void> _onRevoked() async {
    await _credentials.clear();
    _debounce?.cancel();
  }
}

/// What caused a pass. Not persisted — it exists so the reason is visible at
/// the call sites and in a debugger, rather than four anonymous calls.
enum SyncTrigger { launch, resume, periodic, localChange, doorbell, manual }
