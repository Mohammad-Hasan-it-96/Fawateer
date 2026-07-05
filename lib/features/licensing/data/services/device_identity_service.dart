import 'dart:convert';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:crypto/crypto.dart';

import '../../../../core/network/api_config.dart';

/// Produces a stable, privacy-preserving identifier for this install, used as
/// the device's identity in every license call (the backend is keyed by it).
///
/// Android: `SHA-256(ANDROID_ID + salt)` — no permission, survives reinstall on
/// the same signing key. Other platforms fall back (iOS support is a follow-up
/// via `identifierForVendor`); it never throws.
class DeviceIdentityService {
  const DeviceIdentityService();

  static const _androidId = AndroidId();

  Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final raw = await _androidId.getId() ?? '';
        final bytes = utf8.encode('$raw${ApiConfig.deviceIdSalt}');
        return sha256.convert(bytes).toString();
      }
    } catch (_) {
      // Fall through to the constant fallback below.
    }
    // iOS/other: a placeholder until `identifierForVendor` is wired up. The POS
    // targets Android hardware (Bluetooth thermal printers), so this is a
    // documented gap, not a live path.
    return 'fallback_device_id';
  }
}
