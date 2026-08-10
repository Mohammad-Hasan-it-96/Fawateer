import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The app's one local-notification pipe.
///
/// Two features post notifications and they must not each own a copy of the
/// channel: FCM renders foreground pushes through it (the OS only auto-displays
/// notification-type messages while the app is in the background), and low-stock
/// alerts post through it directly (Plan 013 #10). A second `AndroidNotification
/// Channel` with the same id but drifted settings is silently ignored by
/// Android, so the two would quietly diverge.
///
/// Nothing here throws. A missing plugin (host tests), a denied permission or a
/// platform that refuses simply means no notification is shown — never a crash
/// in a caller that was only trying to be helpful.
class LocalNotifier {
  /// Created explicitly before first use — on Android 8+ a notification posted
  /// to a channel that doesn't exist is dropped without any error.
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'fawateer_general',
    'إشعارات فواتير',
    description: 'إشعارات عامة من تطبيق فواتير',
    importance: Importance.high,
  );

  // `FlutterLocalNotificationsPlugin()` returns the package's singleton, so this
  // is the same underlying instance everywhere — the readiness flag is what
  // stops us re-initialising it.
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Idempotent. Returns false when notifications aren't usable on this build.
  Future<bool> ensureReady() async {
    if (_ready) return true;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      _ready = true;
    } catch (_) {
      // Plugin unavailable → callers just don't show anything.
    }
    return _ready;
  }

  /// Ask for the Android 13+ POST_NOTIFICATIONS permission.
  ///
  /// Called at the moment a shop *switches an alert on*, not at startup: asking
  /// before there is anything to explain the request is how permission prompts
  /// get denied for good. Returns false if refused or unavailable.
  Future<bool> requestPermission() async {
    if (!await ensureReady()) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return true; // iOS asks at initialize() time.
      return await android.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Post a notification. [id] replaces any earlier notification with the same
  /// id, which is how a caller updates one in place instead of stacking.
  ///
  /// Returns whether it reached the OS. The result exists because the silent
  /// version was untestable in the field: "no notification appeared" could mean
  /// the plugin refused, the permission was withheld, or nothing was due — and
  /// from outside the app those look identical.
  Future<bool> show({
    required int id,
    String? title,
    String? body,
  }) async {
    if (!await ensureReady()) return false;
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return false;
    }
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
      return true;
    } catch (_) {
      // Never worth crashing for — but the caller is told, so a settings screen
      // can say "that didn't work" instead of leaving the shop guessing.
      return false;
    }
  }

  /// Whether the OS will currently deliver anything we post.
  ///
  /// Distinct from [requestPermission]: this only *asks*, so it is safe to call
  /// when reporting state. A shop that turned notifications off for the app in
  /// the phone's own settings looks exactly like a broken feature otherwise.
  Future<bool> areNotificationsEnabled() async {
    if (!await ensureReady()) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return true;
      return await android.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }
}
