import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../domain/repositories/license_repository.dart';

/// Data-message payload types the server sends when a device's subscription
/// changes. Any of these triggers an in-app license re-check (live-unlock).
const Set<String> _kLicenseMessageTypes = {
  'new_plan_activated',
  'subscription_activated',
  'license_updated',
};

/// Background isolate handler. Must be a top-level / static function annotated
/// with `@pragma('vm:entry-point')`. Fawateer does no background work — the
/// unlock re-check happens when the app next comes to the foreground (or when
/// the user taps the notification) — so this is intentionally a no-op that just
/// lets the OS deliver data messages while the app is backgrounded.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {}

/// Wires Firebase Cloud Messaging to the licensing flow so an operator-side
/// activation unlocks the app **live**, without the user restarting it.
///
/// Entirely optional and self-disabling: if no Firebase project is configured
/// (no `google-services.json`), [Firebase.initializeApp] throws, we swallow it,
/// and the app runs exactly as before (the user just re-checks manually from
/// Settings → Subscription, or on next launch). See `android/README-fcm.md`.
class PushNotificationService {
  PushNotificationService(this._repository);

  final LicenseRepository _repository;

  bool _initialized = false;
  bool _enabled = false;

  /// Called when a license-related push arrives — the app wires this to a
  /// `CheckLicenseEvent` so the router gate flips to active automatically.
  void Function()? _onLicenseChanged;

  /// Idempotent. [onLicenseChanged] is invoked (on the main isolate) whenever a
  /// license-related message is received in the foreground, opened from the
  /// tray, or launched the app from terminated state.
  Future<void> initialize({void Function()? onLicenseChanged}) async {
    if (_initialized) return;
    _initialized = true;
    _onLicenseChanged = onLicenseChanged;

    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Firebase not configured on this build → push disabled, app unaffected.
      return;
    }
    _enabled = true;

    final messaging = FirebaseMessaging.instance;
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    try {
      await messaging.requestPermission();
    } catch (_) {
      // Permission prompt can fail on devices without Play Services; ignore.
    }

    await _syncToken(messaging);
    messaging.onTokenRefresh.listen(_repository.registerPushToken);

    FirebaseMessaging.onMessage.listen(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // App launched from terminated state by tapping the notification.
    final initial = await messaging.getInitialMessage();
    if (initial != null) _handleMessage(initial);
  }

  bool get isEnabled => _enabled;

  Future<void> _syncToken(FirebaseMessaging messaging) async {
    try {
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _repository.registerPushToken(token);
      }
    } catch (_) {
      // Play Services / network may be unavailable; retry on next launch.
    }
  }

  void _handleMessage(RemoteMessage message) {
    final type = (message.data['type'] ?? '').toString().trim();
    if (_kLicenseMessageTypes.contains(type)) {
      _onLicenseChanged?.call();
    }
  }
}
