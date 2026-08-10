import 'package:local_auth/local_auth.dart';

import '../settings/device_preferences.dart';

/// Fingerprint / face as a shortcut past the manager PIN (Plan 016 B).
///
/// **It is a shortcut, never a replacement.** The PIN always stays available:
/// a sensor gets wet fingers, a face fails in the dark, an enrolment is removed,
/// a phone is replaced. A lock whose only key can stop working is a lock that
/// eventually strands the owner.
///
/// **Biometric only — the phone's own unlock code is deliberately not accepted**
/// (`biometricOnly: true`). This lock exists to stop someone who is *already
/// holding the unlocked phone*, and in a small shop the staff who run the till
/// necessarily know the phone's unlock code. Accepting it would hand them the
/// key to the thing it guards. A fingerprint belongs to a person and cannot be
/// passed across the counter.
///
/// Nothing here throws: an unavailable sensor, a missing plugin or a cancelled
/// prompt all read as "not authenticated", and the caller falls back to the PIN.
class BiometricService {
  final DevicePreferences _prefs;
  final LocalAuthentication _auth;

  BiometricService(this._prefs, {LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  /// Whether the owner turned the shortcut on **for this phone**.
  ///
  /// Stored in [DevicePreferences], not the database, because an enrolled
  /// fingerprint is a fact about a handset — restoring a backup onto a new
  /// phone must not claim that phone has one. The PIN hash travels with the
  /// books; this does not.
  static const String enabledKey = 'pref_manager_biometric';

  Future<bool> isEnabled() async =>
      await _prefs.read(enabledKey) == 'true';

  Future<void> setEnabled(bool value) =>
      _prefs.write(enabledKey, value.toString());

  /// Whether this phone can actually check a fingerprint or face *right now*.
  ///
  /// All three checks matter: the hardware can exist with nothing enrolled,
  /// and `isDeviceSupported` is false when the user has no device lock at all
  /// (Android refuses biometrics without one).
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      // No plugin (host tests), no sensor, or a platform that refused to
      // answer. Not being able to ask is the same as "no".
      return false;
    }
  }

  /// True when the shortcut is both switched on and usable. What the guard
  /// checks before offering the prompt.
  Future<bool> isReady() async => await isEnabled() && await isAvailable();

  /// Show the system prompt. False on failure, cancel, or anything unexpected —
  /// the caller then asks for the PIN, which is always the way through.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          // See the class comment: the phone's unlock code must not open this.
          biometricOnly: true,
          // Survive the app being backgrounded mid-prompt (a notification, a
          // call) instead of silently failing.
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
