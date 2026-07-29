import '../../../core/database/daos/settings_dao.dart';

/// Where this device is up to in the sync conversation (Plan 002, Phase 1).
///
/// Two independent positions, and conflating them is the bug the 2026-07-29
/// exchange was mostly about:
///
///  - [pushWatermark] is an **authored HLC** — "every local change stamped at
///    or before this has been handed to the server". It is our own clock.
///  - [pullCursor] is a **server sequence** — "every change the server had at
///    or before this has been handed to us". It is the server's counter, and it
///    is per-business.
///
/// They measure different things on different clocks and never convert. Using
/// arrival order to resolve authorship is what lets a device that was offline
/// for three days overwrite fresher edits.
///
/// Both live in `AppSettings` rather than SharedPreferences, unlike the seat
/// credential: they describe the *data*, so a bootstrap restore that replaces
/// the database must replace them too — a cursor from the old database would
/// skip everything the snapshot did not contain.
class SyncStateStore {
  static const kPushWatermark = 'sync_push_watermark';
  static const kPullCursor = 'sync_pull_cursor';
  static const kLastSyncAt = 'sync_last_at';

  final SettingsDao _settings;

  const SyncStateStore(this._settings);

  Future<String> pushWatermark() async =>
      await _settings.getValue(kPushWatermark) ?? '';

  Future<void> setPushWatermark(String hlc) =>
      _settings.setValue(kPushWatermark, hlc);

  Future<int> pullCursor() async {
    final raw = await _settings.getValue(kPullCursor);
    return int.tryParse(raw ?? '') ?? 0;
  }

  /// Advance the cursor. **Never moves backwards**: a server that answers an
  /// unexpected `next_cursor` (a rollback, a misrouted response) would
  /// otherwise make the device re-pull and re-apply history, and while the
  /// merge is idempotent, the re-application is wasted work on every tick
  /// forever.
  Future<void> setPullCursor(int cursor) async {
    if (cursor <= await pullCursor()) return;
    await _settings.setValue(kPullCursor, cursor.toString());
  }

  /// Force the cursor to an exact value, used only by the bootstrap handoff —
  /// where the correct starting point genuinely comes from outside and may be
  /// lower than whatever this (freshly restored) database happened to hold.
  Future<void> resetPullCursor(int cursor) =>
      _settings.setValue(kPullCursor, cursor.toString());

  Future<DateTime?> lastSyncAt() async {
    final raw = await _settings.getValue(kLastSyncAt);
    final ms = int.tryParse(raw ?? '');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastSyncAt(DateTime at) =>
      _settings.setValue(kLastSyncAt, at.millisecondsSinceEpoch.toString());
}
