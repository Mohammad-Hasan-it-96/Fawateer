import 'dart:convert';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../../../core/network/api_config.dart';

/// Produces a stable, privacy-preserving identifier for this install, used as
/// the device's identity in every license call (the backend is keyed by it).
///
/// - Android: `SHA-256(ANDROID_ID + salt)` — no permission, survives reinstall
///   on the same signing key.
/// - iOS: `SHA-256(identifierForVendor + salt)` — no permission, stable while
///   any app from the same vendor stays installed (resets once all are removed).
///
/// The raw id is always hashed with the salt before it leaves this class, so the
/// two platforms produce interchangeable opaque tokens. Every path is wrapped so
/// it never throws — an unreadable id falls back to a constant placeholder.
class DeviceIdentityService {
  const DeviceIdentityService();

  static const _androidId = AndroidId();

  Future<String> getDeviceId() async {
    try {
      final raw = await _rawPlatformId();
      if (raw != null && raw.isNotEmpty) {
        final bytes = utf8.encode('$raw${ApiConfig.deviceIdSalt}');
        return sha256.convert(bytes).toString();
      }
    } catch (_) {
      // Fall through to the constant fallback below.
    }
    // Unsupported platform, or the platform returned no id (e.g. iOS
    // `identifierForVendor` can be null before the first device unlock).
    return 'fallback_device_id';
  }

  /// The unhashed, platform-native identifier, or `null` when unavailable.
  Future<String?> _rawPlatformId() async {
    if (Platform.isAndroid) {
      return _androidId.getId();
    }
    if (Platform.isIOS) {
      final info = await DeviceInfoPlugin().iosInfo;
      return info.identifierForVendor;
    }
    return null;
  }
}
