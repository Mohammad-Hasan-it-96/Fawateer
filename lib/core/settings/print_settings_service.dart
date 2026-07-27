import '../database/daos/settings_dao.dart';

/// Whether the checkout shows its receipt-print button and auto-prints on a
/// confirmed sale (Plan 011 #6).
///
/// **On by default** — most shops print. A shop with no printer can turn it off
/// to hide the button and stop the auto-print attempt (and its "printer not
/// connected" red notice) on every sale. Stored as a single [AppSettings]
/// key-value row (no table, no migration), same as the strict-inventory flag.
class PrintSettingsService {
  final SettingsDao _dao;
  const PrintSettingsService(this._dao);

  static const _showPrintButtonKey = 'show_print_button';

  /// True unless the owner has explicitly turned printing off. Any value other
  /// than the literal `'false'` (including an unset key) reads as on.
  Future<bool> isPrintButtonEnabled() async {
    final raw = await _dao.getValue(_showPrintButtonKey);
    return raw != 'false';
  }

  /// Persist the print-button/auto-print flag.
  Future<void> setPrintButtonEnabled(bool enabled) =>
      _dao.setValue(_showPrintButtonKey, enabled.toString());
}
