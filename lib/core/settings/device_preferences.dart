import 'package:shared_preferences/shared_preferences.dart';

/// Preferences that belong to **this phone**, not to the shop's books.
///
/// Theme and text size describe a person and a screen — whose eyes, how big the
/// display is. They are not facts about the business, and they are the only
/// settings in the app for which that is true today (the printer's MAC address
/// is the next-best candidate and would fit here for the same reason).
///
/// They live in `SharedPreferences` rather than in the app database because:
///
/// - **A Drive restore replaces the whole SQLite file.** A shop restoring a
///   backup taken on another phone would otherwise inherit that phone's text
///   size along with its books. The books are meant to travel between devices;
///   the display settings are not.
/// - They are read **before `runApp`**, so the very first frame is already the
///   right size and theme. This is a plain file read with no database to open,
///   migrate, and keep open first.
/// - They are outside the backup, which is correct: nobody wants their font
///   size restored, and losing it costs one tap.
///
/// Both survive an app update either way — Android keeps app data across an
/// update, and so does the database. What changes here is that they no longer
/// depend on the shop's data file at all.
class DevicePreferences {
  /// Light/dark/system, stored by name (see `ThemeController`).
  static const String themeMode = 'pref_theme_mode';

  /// App-wide text size, stored by `AppFontScale.name`.
  static const String fontScale = 'pref_font_scale';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// The stored value, or null when nothing has been written yet. Never
  /// throws — an unreadable preference is a default, not a failure.
  Future<String?> read(String key) async {
    try {
      return (await _instance).getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, String value) async {
    try {
      await (await _instance).setString(key, value);
    } catch (_) {
      // Ignored by design: a cosmetic preference that fails to save costs one
      // tap on the next launch and must never interrupt anything.
    }
  }
}
