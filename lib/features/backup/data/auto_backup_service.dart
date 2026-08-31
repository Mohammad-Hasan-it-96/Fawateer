import 'dart:async';

import '../../../core/database/daos/settings_dao.dart';
import '../../sync/data/sync_credential_store.dart';
import '../domain/repositories/backup_repository.dart';

/// Runs a cloud backup on its own, so the shopkeeper never has to remember to.
///
/// **Foreground-triggered by design** (Plan 001): there is no `WorkManager` job
/// and no background service. Android's background limits, battery policy and
/// OEM task-killers make a real scheduler a large support surface for marginal
/// benefit in an app the shop opens every day — a check on launch/resume is
/// simpler and reaches the same outcome.
///
/// It is deliberately silent. Every failure path (offline, signed out, Drive
/// erroring) leaves [SettingsDao] untouched so the next trigger retries, and
/// none of them surface UI: an automatic backup the user did not ask for must
/// never interrupt a sale. The Backup page remains the place where backup state
/// is visible and errors are explained.
class AutoBackupService {
  AutoBackupService(this._repo, this._settings, this._credentials);

  final BackupRepository _repo;
  final SettingsDao _settings;

  /// Reads this phone's sync role. See [isBackupDevice].
  final SyncCredentialStore _credentials;

  /// Opt-out flag, stored in the existing key-value table (no migration).
  static const _kEnabled = 'backup_auto_enabled';

  /// How stale the last backup must be before a trigger acts.
  static const cadence = Duration(hours: 24);

  /// Guards against overlapping runs — launch and resume can fire together, and
  /// two concurrent `VACUUM INTO` + uploads would be pure waste.
  Future<void>? _inFlight;

  /// Whether this phone may write the shop's backups to Drive.
  ///
  /// **One shop, one backup history — written by the main phone only.** Two
  /// linked phones hold the same books, so a linked phone backing up as well
  /// produces a second stream of snapshots into the same Drive folder, taken at
  /// a different moment and very likely slightly behind. The owner then picks
  /// from a list where half the entries are a copy of the shop as some other
  /// handset saw it, with nothing on screen saying which is which — and
  /// restoring the wrong one silently rolls the shop back.
  ///
  /// It also makes the auto-backup cadence meaningless: two devices each
  /// checking "is the last backup 24h old?" against one shared timestamp means
  /// whichever opens first wins and the other never runs, so which phone the
  /// shop's backup came from becomes a matter of who unlocked their screen
  /// first that morning.
  ///
  /// **Restore is deliberately NOT restricted.** Pulling a snapshot down onto a
  /// linked phone is how an owner reseeds it by hand, and it is the recovery
  /// path when the automatic bootstrap has not run. Only *writing* is owner-only.
  ///
  /// A device that is not enrolled at all is allowed: a single-phone shop is
  /// its own main phone.
  Future<bool> isBackupDevice() async {
    try {
      final session = await _credentials.load();
      return session == null || session.isOwner;
    } catch (_) {
      // Unreadable credentials must not silently stop a single-phone shop's
      // backups — the failure direction that loses data is the costly one.
      return true;
    }
  }

  /// Whether this phone shares its shop with others.
  ///
  /// Used by the restore flow, not by backup: **restoring on a linked phone
  /// silently diverges the shop.** A Drive snapshot's rows carry
  /// `updated_at = ''` — "predates sync, never push me" — so the restored
  /// catalogue is invisible to the replication log and the other phones keep
  /// showing what they had. Nothing errors, both screens report success, and
  /// the two tills quietly disagree about the price of everything.
  ///
  /// The fix is not to re-stamp the restored rows and push the whole shop:
  /// that claims this device authored every row *now*, so it would win
  /// last-write-wins against a genuine later edit made on the other till. The
  /// bootstrap snapshot exists for precisely this handoff, so the honest
  /// instruction is to link the other phones again — which reseeds them from
  /// exactly this database.
  Future<bool> isLinkedToOtherPhones() async {
    try {
      return await _credentials.load() != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    final raw = await _settings.getValue(_kEnabled);
    // Default ON: a shop that connected Drive wants its data backed up. Only an
    // explicit opt-out turns it off.
    return raw == null || raw == 'true';
  }

  Future<void> setEnabled(bool value) =>
      _settings.setValue(_kEnabled, value.toString());

  /// Back up if enabled, signed in, and the last one is older than [cadence].
  ///
  /// Never throws and never reports: callers fire it and forget it.
  Future<void> maybeRun() {
    return _inFlight ??= _run().whenComplete(() => _inFlight = null);
  }

  Future<void> _run() async {
    try {
      if (!await isEnabled()) return;
      // Checked before the Drive round trip, not after: a linked phone should
      // never even be asked to sign in for this.
      if (!await isBackupDevice()) return;
      // Signed out is the normal state for a user who never set backup up —
      // not an error, and not something to nag about here.
      if (!await _repo.isSignedIn()) return;

      final last = await _repo.lastBackupAt();
      if (last != null) {
        final elapsed = DateTime.now().difference(last);
        // A negative elapsed means the device clock moved backwards; treat it
        // as due rather than trusting it, so a wrong clock can't wedge backups
        // off indefinitely.
        if (!elapsed.isNegative && elapsed < cadence) return;
      }

      // Offline or Drive-side failures come back as Left and are dropped: the
      // next launch or resume simply tries again.
      await _repo.backupNow();
    } catch (_) {
      // Belt and braces — an automatic backup must not be able to crash the app.
    }
  }
}
