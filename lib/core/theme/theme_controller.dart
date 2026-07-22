import 'package:flutter/material.dart';

import '../database/daos/settings_dao.dart';

/// Holds the user's light/dark/system preference and persists it.
///
/// A [ChangeNotifier] rather than a BLoC: this is one enum with no async
/// states, no failure channel and no events worth naming — the same reason the
/// router's licence gate bridges to a `ChangeNotifier` instead of adding a
/// second BLoC. `MyApp` listens and rebuilds `MaterialApp.router`.
///
/// Storage is a single [AppSettings] row (`theme_mode`), not a new table —
/// same treatment as `printer_mac` and the exchange rate.
class ThemeController extends ChangeNotifier {
  ThemeController(this._settingsDao);

  final SettingsDao _settingsDao;

  static const String _key = 'theme_mode';

  /// Light until the stored value is read, and light when nothing is stored.
  ///
  /// **The default is deliberately light, not `system`.** Page bodies still
  /// hold hardcoded light colours, so a device set to dark at the OS level
  /// would otherwise show a half-dark app on first launch, with no action from
  /// the user. Dark is opt-in until those pages are migrated; revisit this
  /// default then.
  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  /// Reads the stored preference. Call once during startup, before `runApp`,
  /// so the first frame is already in the right mode and the app doesn't flash
  /// light-then-dark. Never throws — an unreadable setting just means light.
  Future<void> load() async {
    try {
      final stored = await _settingsDao.getValue(_key);
      if (stored != null) _mode = _decode(stored);
    } catch (_) {
      // Leave the default; a missing/corrupt pref must not block startup.
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    // Persist after notifying: the repaint is what the user is waiting on, and
    // a failed write only costs the preference on next launch.
    try {
      await _settingsDao.setValue(_key, _encode(mode));
    } catch (_) {
      // Ignored by design — see above.
    }
  }

  /// Persisted **by name**, never by index, so reordering `ThemeMode` upstream
  /// can't silently remap a stored preference. Matches how `ProductSaleType`
  /// and `CashTransactionType` are stored.
  static String _encode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  static ThemeMode _decode(String value) => switch (value) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };
}
