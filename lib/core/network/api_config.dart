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

  /// Base URL for all API calls. Overridable at runtime via [ApiClient].
  static const String defaultBaseUrl =
      'https://harrypotter.foodsalebot.com/api';

  // ── Operator contact for manual (operator-driven) activation ──────────────
  // A plan request is filed as `status: 'pending'` on the server, then the user
  // is funnelled to one of these channels; the operator activates the device
  // server-side. Replace the placeholders with the real support line.
  /// WhatsApp number in international format, digits only (e.g. '9639xxxxxxxx').
  static const String supportWhatsApp = '';

  /// Telegram username without the leading '@' (e.g. 'FawateerSupport').
  static const String supportTelegram = '';

  /// Salt mixed into the raw device id before hashing. App-specific so the same
  /// physical device yields a different id per app.
  static const String deviceIdSalt = 'fawateer_pos_app';
}
