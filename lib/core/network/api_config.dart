/// Network configuration for the app's server communication.
///
/// Points at the **EVOTECH platform** (`evotech-core`), which serves this app's
/// contract — `create_device`/`check_device`/`update_my_data`/`getPlans`/
/// `add_review` — unversioned and unauthenticated, identified by [appName] in
/// the body. It previously reused the Smart-Agent backend; the platform was
/// built to match these exact payloads, so nothing in this feature moved.
class ApiConfig {
  ApiConfig._();

  /// Identifies this app to the shared backend so licenses don't cross apps.
  static const String appName = 'Fawateer';

  /// The baked-in base URL — used until the remote config (`fawateer.json`) is
  /// fetched, and as the fallback if that fetch ever fails.
  ///
  /// The `/api/fawateer` **namespace**, not a bare `/api`: the platform serves
  /// several apps, and `getPlans` carries no `app_name`, so the URL is the only
  /// thing that can tell it which catalog to return. Today every namespace
  /// answers alike; keeping this segment is what lets Fawateer be given its own
  /// pricing later with no release.
  ///
  /// This being a *fallback* is the point: it is what a failed config fetch
  /// falls back to, so it must be somewhere correct. It used to name the old
  /// backend, which meant a fetch failure silently routed users to the wrong
  /// server and looked like success.
  static const String defaultBaseUrl =
      'https://api.evotech-sys.com/api/fawateer';

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
