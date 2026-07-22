import 'dart:async';

import '../../../core/database/daos/settings_dao.dart';
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
  AutoBackupService(this._repo, this._settings);

  final BackupRepository _repo;
  final SettingsDao _settings;

  /// Opt-out flag, stored in the existing key-value table (no migration).
  static const _kEnabled = 'backup_auto_enabled';

  /// How stale the last backup must be before a trigger acts.
  static const cadence = Duration(hours: 24);

  /// Guards against overlapping runs — launch and resume can fire together, and
  /// two concurrent `VACUUM INTO` + uploads would be pure waste.
  Future<void>? _inFlight;

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
