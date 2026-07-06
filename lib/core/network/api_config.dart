/// Network configuration for the app's server communication.
///
/// Fawateer currently reuses the Smart-Agent backend (the same
/// `create_device`/`check_device`/`getPlans` endpoints), distinguished only by
/// [appName]. When Fawateer's own server is ready, change [defaultBaseUrl]
/// (or override it at runtime) — nothing else needs to move.
class ApiConfig {
  ApiConfig._();

  /// Identifies this app to the shared backend so licenses don't cross apps.
  static const String appName = 'Fawateer';

  /// The baked-in base URL — used until the remote config (fawateer_version.json)
  /// is fetched, and as the fallback if that fetch ever fails.
  static const String defaultBaseUrl =
      'https://harrypotter.foodsalebot.com/api';

  /// The effective base URL for all API calls. Starts at [defaultBaseUrl] and is
  /// overwritten at startup by `RemoteConfigService` from the remote config, so
  /// the server can be moved without shipping a new build. [ApiClient] reads this
  /// per-request.
  static String baseUrl = defaultBaseUrl;

  // ── Operator contact for manual (operator-driven) activation ──────────────
  // A plan request is filed as `status: 'pending'` on the server, then the user
  // is funnelled to one of these channels; the operator activates the device
  // server-side. These are the baked-in defaults; `RemoteConfigService` may
  // overwrite them from the remote config's `support` block at startup.
  /// WhatsApp number in international format, digits only (e.g. '9639xxxxxxxx').
  static String supportWhatsApp = '963959027196';

  /// Telegram contact — either a full `https://t.me/...` link or a bare username.
  static String supportTelegram = 'https://t.me/+963959027196';

  /// Support email address for plan requests.
  static String supportEmail = 'mohamad.hasan.it.96@gmail.com';

  /// Salt mixed into the raw device id before hashing. App-specific so the same
  /// physical device yields a different id per app.
  static const String deviceIdSalt = 'fawateer_pos_app';
}
