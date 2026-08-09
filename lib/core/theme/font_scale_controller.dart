import 'package:flutter/widgets.dart';

import '../database/daos/settings_dao.dart';

/// App-wide text-size options (Plan 011 #1). Persisted **by name** (never index,
/// so reordering can't remap a stored choice) in one [AppSettings] row — same
/// treatment as the theme mode.
enum AppFontScale {
  /// Added after a shop reported action labels still running out of room at
  /// [small] on a narrow phone. **0.8 is the floor**, not a step on the way
  /// down: below it the shop's own product names stop being readable across a
  /// counter, and the fix for a cramped screen becomes a screen nobody can use.
  tiny(0.8),
  small(0.9),
  normal(1.0),
  large(1.15),
  extraLarge(1.3);

  const AppFontScale(this.factor);

  /// Multiplier applied to every text size via `MediaQuery.textScaler`.
  final double factor;
}

/// Holds the user's app-wide font-size preference and persists it.
///
/// A [ChangeNotifier] rather than a BLoC — one enum, no async states, no failure
/// channel — for the same reasons as `ThemeController`. `_ThemedApp` listens and
/// wraps the whole app in a `MediaQuery` whose `textScaler` is [factor], so the
/// choice scales every screen at once. The choice is cosmetic: a failed write
/// only costs the preference on the next launch, never blocks anything.
class FontScaleController extends ChangeNotifier {
  FontScaleController(this._settingsDao);

  final SettingsDao _settingsDao;

  static const String _key = 'font_scale';

  AppFontScale _scale = AppFontScale.normal;
  AppFontScale get scale => _scale;
  double get factor => _scale.factor;

  /// Reads the stored preference. Call once during startup, before `runApp`, so
  /// the first frame is already at the right size. Never throws.
  Future<void> load() async {
    try {
      final stored = await _settingsDao.getValue(_key);
      if (stored != null) _scale = _decode(stored);
    } catch (_) {
      // Leave the default; a missing/corrupt pref must not block startup.
    }
    notifyListeners();
  }

  Future<void> setScale(AppFontScale scale) async {
    if (scale == _scale) return;
    _scale = scale;
    notifyListeners();
    // Persist after notifying: the repaint is what the user is waiting on.
    try {
      await _settingsDao.setValue(_key, scale.name);
    } catch (_) {
      // Ignored by design — see above.
    }
  }

  static AppFontScale _decode(String value) {
    for (final s in AppFontScale.values) {
      if (s.name == value) return s;
    }
    return AppFontScale.normal;
  }
}
