import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../../core/notifications/local_notifier.dart';
import '../../domain/repositories/license_repository.dart';

/// Data-message payload types the server sends when a device's subscription
/// changes. Any of these triggers an in-app license re-check (live-unlock).
const Set<String> _kLicenseMessageTypes = {
  'new_plan_activated',
  'subscription_activated',
  'license_updated',
};

/// The multi-device sync doorbell (Plan 002, Phase 1).
///
/// Carries **no data** — it only says "the server has something for you", and
/// the device then runs an ordinary pull. Deliberately not a payload: a change
/// pushed inside a notification would arrive out of order relative to the pull
/// cursor, could be dropped by the OS under battery policy, and would have to be
/// merged from a background isolate with no database open. A doorbell just makes
/// the next pull happen sooner than the timer would.
const Set<String> _kSyncMessageTypes = {
  'sync_changes_available',
  'sync_device_revoked',
};

/// What a push message means to this app.
enum PushMessageKind {
  /// Re-check the subscription (and, in the foreground, say so).
  license,

  /// Run a sync pass. Silent.
  sync,

  /// Anything else — including a plain notification with no `type` at all,
  /// which the OS has already displayed and which needs no action from us.
  ignored,
}

/// Route one message's data payload. Pure, and separate from the service so it
/// can be tested without a Firebase project.
///
/// **Sync is matched before licence, and that order is load-bearing.** The two
/// vocabularies are disjoint today, but the licence branch ends in a
/// subscription re-check and a "subscription activated" banner — so if a sync
/// type ever fell through to it, every sale the other till made would pop that
/// banner on this one. Checking the narrower, higher-frequency case first makes
/// that impossible rather than merely unlikely.
PushMessageKind classifyPushMessage(Map<String, dynamic> data) {
  final type = (data['type'] ?? '').toString().trim();
  if (_kSyncMessageTypes.contains(type)) return PushMessageKind.sync;
  if (_kLicenseMessageTypes.contains(type)) return PushMessageKind.license;
  return PushMessageKind.ignored;
}

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

  /// Foreground display of notification-type FCM messages. The OS only
  /// auto-displays those while the app is in the **background**; in the
  /// foreground they'd be silently swallowed unless we render one ourselves.
  ///
  /// Shared with low-stock alerts (Plan 013 #10) rather than owning a private
  /// copy: both post to the same Android channel, and two definitions of one
  /// channel id drift apart without any error to notice.
  final _localNotifier = LocalNotifier();

  /// Called when a license-related push arrives — the app wires this to a
  /// `CheckLicenseEvent` so the router gate flips to active automatically.
  void Function()? _onLicenseChanged;

  /// Called only when a license-related push arrives while the app is in the
  /// **foreground** — the app wires this to a visible in-app banner. (Background
  /// / terminated deliveries surface as a system tray notification instead, so
  /// they don't need one.)
  void Function()? _onForegroundLicenseChange;

  /// Called when the sync doorbell rings — the app wires this to a sync pass.
  /// Silent by design: the shopkeeper should not be notified that a routine
  /// pull is about to happen, only see the result appear.
  void Function()? _onSyncChanged;

  /// Idempotent. [onLicenseChanged] is invoked (on the main isolate) whenever a
  /// license-related message is received in the foreground, opened from the
  /// tray, or launched the app from terminated state. [onForegroundLicenseChange]
  /// fires additionally, but only for foreground receipts (for an in-app banner).
  Future<void> initialize({
    void Function()? onLicenseChanged,
    void Function()? onForegroundLicenseChange,
    void Function()? onSyncChanged,
  }) async {
    if (_initialized) return;
    _initialized = true;
    _onLicenseChanged = onLicenseChanged;
    _onForegroundLicenseChange = onForegroundLicenseChange;
    _onSyncChanged = onSyncChanged;

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

    await _localNotifier.ensureReady();

    // Sync the current token on EVERY startup (the repository skips the
    // network call when the server already confirmed this exact token), and
    // re-send whenever FCM rotates it while the app is running. Without both,
    // the server's stored token goes stale and sends fail with NotRegistered.
    await _syncToken(messaging);
    messaging.onTokenRefresh.listen(_repository.registerPushToken);

    FirebaseMessaging.onMessage.listen((m) {
      _showForegroundNotification(m);
      _handleMessage(m, foreground: true);
    });
    FirebaseMessaging.onMessageOpenedApp
        .listen((m) => _handleMessage(m, foreground: false));

    // App launched from terminated state by tapping the notification.
    final initial = await messaging.getInitialMessage();
    if (initial != null) _handleMessage(initial, foreground: false);
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

  /// Render a notification-type FCM message received in the foreground.
  /// Data-only messages (the license live-unlock) carry no `notification`
  /// payload and are skipped — they surface via the in-app banner instead.
  void _showForegroundNotification(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    final title = n.title ?? '';
    final body = n.body ?? '';
    // Message hash as the id, so two different pushes stack rather than
    // replacing each other (unlike low-stock, which deliberately reuses one).
    _localNotifier.show(
      id: message.hashCode,
      title: title.isEmpty ? null : title,
      body: body.isEmpty ? null : body,
    );
  }

  void _handleMessage(RemoteMessage message, {required bool foreground}) {
    switch (classifyPushMessage(message.data)) {
      case PushMessageKind.sync:
        _onSyncChanged?.call();
      case PushMessageKind.license:
        _onLicenseChanged?.call();
        if (foreground) _onForegroundLicenseChange?.call();
      case PushMessageKind.ignored:
        break;
    }
  }
}
