import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/license_status.dart';
import '../../domain/guards/license_guards.dart';

/// Local persistence for license state (SharedPreferences). Blends the raw
/// cached values with the offline/clock-tamper guards when reading, so callers
/// get a ready-to-gate [LicenseStatus] even with no connectivity.
///
/// Note: a documents-dir mirror file (so "clear app data" can't reset expiry)
/// is a deliberate follow-up hardening step; prefs cover the common case.
class LicenseLocalStorage {
  static const _kVerified = 'lic_verified';
  static const _kExpires = 'lic_expires_at'; // epoch ms
  static const _kPlan = 'lic_plan';
  static const _kTrial = 'lic_is_trial';
  static const _kLastSync = 'lic_last_sync'; // epoch ms
  static const _kTrusted = 'lic_trusted_time'; // epoch ms (server time baseline)
  // Server-minus-device clock skew (seconds) captured at the last sync, so the
  // tamper check compares like with like (see LicenseGuards.isTimeTampered).
  static const _kTimeOffset = 'lic_time_offset';
  // Highest device time ever observed (epoch ms), advanced monotonically on
  // every status read — anchors rollback detection when the server is far away.
  static const _kMaxSeen = 'lic_max_seen_time';
  static const _kName = 'lic_agent_name';
  static const _kPhone = 'lic_agent_phone';
  static const _kPushToken = 'lic_push_token'; // current device FCM token
  // Last token the server *confirmed* receiving (2xx). Distinct from
  // [_kPushToken]: that one is cached before any network call so activation can
  // attach it; this one is written only after a successful send, so a failed
  // send retries on the next launch instead of being wrongly skipped.
  static const _kLastSentToken = 'last_sent_fcm_token';
  // Server-side *masked* Drive account (e.g. 'y••••n@gmail.com') echoed by
  // check_device. A hint for a reinstalled user, never a usable address — see
  // [saveGoogleAccountHint].
  static const _kGoogleHint = 'lic_google_account_hint';
  static const _kReviewSent = 'lic_review_sent'; // asked for a rating only once

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Persist the server-derived part of a status. Does not touch the trusted
  /// time / last-sync markers — those are updated via [markSynced].
  Future<void> saveStatus(LicenseStatus status) async {
    final p = await _p;
    await p.setBool(_kVerified, status.isVerified);
    await p.setBool(_kTrial, status.isTrial);
    if (status.expiresAt != null) {
      await p.setInt(_kExpires, status.expiresAt!.millisecondsSinceEpoch);
    } else {
      await p.remove(_kExpires);
    }
    if (status.planName != null) {
      await p.setString(_kPlan, status.planName!);
    } else {
      await p.remove(_kPlan);
    }
  }

  /// Record a successful server contact. [serverTime] (when provided) becomes
  /// the trusted baseline for clock-tamper detection, and the server-vs-device
  /// skew is captured alongside it so the tamper check can compensate.
  Future<void> markSynced(DateTime now, {DateTime? serverTime}) async {
    final p = await _p;
    await p.setInt(_kLastSync, now.millisecondsSinceEpoch);
    if (serverTime != null) {
      await p.setInt(_kTrusted, serverTime.millisecondsSinceEpoch);
      await p.setInt(_kTimeOffset, serverTime.difference(now).inSeconds);
      // Server contact re-establishes ground truth — RESET the max-seen anchor
      // (even backwards). Otherwise a user who accidentally set the clock a
      // month ahead and then corrected it would trip the rollback guard until
      // the real clock caught up to the bogus future timestamp, with no way
      // out. Post-sync, rollbacks are caught by the trusted-time check.
      await p.setInt(_kMaxSeen, now.millisecondsSinceEpoch);
    }
  }

  Future<void> saveAgent(String name, String phone) async {
    final p = await _p;
    await p.setString(_kName, name);
    await p.setString(_kPhone, phone);
  }

  Future<({String? name, String? phone})> loadAgent() async {
    final p = await _p;
    return (name: p.getString(_kName), phone: p.getString(_kPhone));
  }

  /// The device's current FCM token (cached before any network call), so
  /// activation can attach it to `create_device`.
  Future<String?> loadPushToken() async => (await _p).getString(_kPushToken);

  Future<void> savePushToken(String token) async =>
      (await _p).setString(_kPushToken, token);

  /// The last token the server confirmed (2xx) — used to skip redundant
  /// re-sends on every launch while still retrying after a failed one.
  Future<String?> loadLastSentPushToken() async =>
      (await _p).getString(_kLastSentToken);

  Future<void> saveLastSentPushToken(String token) async =>
      (await _p).setString(_kLastSentToken, token);

  /// Cache the masked Drive account echoed by `check_device`. A null/blank value
  /// removes the key, so a device whose backup account was cleared server-side
  /// stops showing a stale hint.
  Future<void> saveGoogleAccountHint(String? masked) async {
    final p = await _p;
    if (masked == null || masked.trim().isEmpty) {
      await p.remove(_kGoogleHint);
    } else {
      await p.setString(_kGoogleHint, masked.trim());
    }
  }

  Future<String?> loadGoogleAccountHint() async =>
      (await _p).getString(_kGoogleHint);

  /// Set once the device's review reaches the server, so the app asks only once.
  Future<bool> loadReviewSent() async => (await _p).getBool(_kReviewSent) ?? false;

  Future<void> markReviewSent() async => (await _p).setBool(_kReviewSent, true);

  /// Read the cached status with offline/tamper guards applied against [now].
  ///
  /// Also advances the monotonic max-seen-time anchor as a side effect: every
  /// status read observes the clock, so the anchor stays fresh without any
  /// separate bookkeeping call site.
  Future<LicenseStatus> loadStatus(DateTime now) async {
    final p = await _p;
    final expiresMs = p.getInt(_kExpires);
    final lastSyncMs = p.getInt(_kLastSync);
    final trustedMs = p.getInt(_kTrusted);
    final offsetSeconds = p.getInt(_kTimeOffset) ?? 0;
    final maxSeenMs = p.getInt(_kMaxSeen);

    final lastSync = lastSyncMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
    final trusted =
        trustedMs == null ? null : DateTime.fromMillisecondsSinceEpoch(trustedMs);
    final maxSeen =
        maxSeenMs == null ? null : DateTime.fromMillisecondsSinceEpoch(maxSeenMs);

    // Judge against the anchor as it was BEFORE this observation, then advance
    // it (never backwards — that's the whole point of the anchor).
    final tampered = LicenseGuards.isTimeTampered(trusted, now,
            timeOffsetSeconds: offsetSeconds) ||
        LicenseGuards.isClockRolledBack(maxSeen, now);
    if (maxSeenMs == null || now.millisecondsSinceEpoch > maxSeenMs) {
      await p.setInt(_kMaxSeen, now.millisecondsSinceEpoch);
    }

    return LicenseStatus(
      isVerified: p.getBool(_kVerified) ?? false,
      isTrial: p.getBool(_kTrial) ?? false,
      planName: p.getString(_kPlan),
      expiresAt: expiresMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expiresMs),
      lastServerSync: lastSync,
      offlineLimitExceeded: LicenseGuards.isOfflineLimitExceeded(lastSync, now),
      timeTampered: tampered,
    );
  }
}
