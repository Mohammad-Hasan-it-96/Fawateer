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
  static const _kName = 'lic_agent_name';
  static const _kPhone = 'lic_agent_phone';
  static const _kPushToken = 'lic_push_token'; // last FCM token sent to server
  // Server-side *masked* Drive account (e.g. 'y••••n@gmail.com') echoed by
  // check_device. A hint for a reinstalled user, never a usable address — see
  // [saveGoogleAccountHint].
  static const _kGoogleHint = 'lic_google_account_hint';

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
  /// the trusted baseline for clock-tamper detection.
  Future<void> markSynced(DateTime now, {DateTime? serverTime}) async {
    final p = await _p;
    await p.setInt(_kLastSync, now.millisecondsSinceEpoch);
    if (serverTime != null) {
      await p.setInt(_kTrusted, serverTime.millisecondsSinceEpoch);
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

  /// The last FCM token we successfully handed to the server, so activation can
  /// attach the current token and we can skip redundant re-registrations.
  Future<String?> loadPushToken() async => (await _p).getString(_kPushToken);

  Future<void> savePushToken(String token) async =>
      (await _p).setString(_kPushToken, token);

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

  /// Read the cached status with offline/tamper guards applied against [now].
  Future<LicenseStatus> loadStatus(DateTime now) async {
    final p = await _p;
    final expiresMs = p.getInt(_kExpires);
    final lastSyncMs = p.getInt(_kLastSync);
    final trustedMs = p.getInt(_kTrusted);

    final lastSync = lastSyncMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
    final trusted =
        trustedMs == null ? null : DateTime.fromMillisecondsSinceEpoch(trustedMs);

    return LicenseStatus(
      isVerified: p.getBool(_kVerified) ?? false,
      isTrial: p.getBool(_kTrial) ?? false,
      planName: p.getString(_kPlan),
      expiresAt: expiresMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expiresMs),
      lastServerSync: lastSync,
      offlineLimitExceeded: LicenseGuards.isOfflineLimitExceeded(lastSync, now),
      timeTampered: LicenseGuards.isTimeTampered(trusted, now),
    );
  }
}
