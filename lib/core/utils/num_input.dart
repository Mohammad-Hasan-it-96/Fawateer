import 'package:flutter/services.dart';

/// Shared numeric-input safety for money/quantity fields.
///
/// `keyboardType: numberWithOptions` is only a soft-keyboard hint — it does not
/// restrict what can be typed or **pasted** (a hardware keyboard or paste can
/// inject `-5`, `abc`, `Infinity`, `1e309`). These helpers close that gap:
/// [decimalFormatters] restrict keystrokes/paste to digits + one separator, and
/// [parseFlexibleNumber] normalizes Arabic-Indic/Persian digits and Arabic/comma
/// decimal separators, rejecting anything non-finite (`Infinity`/`NaN`) that
/// would later crash `toStringAsFixed`.
class NumInput {
  NumInput._();

  // ASCII digits, Arabic-Indic (٠-٩), Persian (۰-۹), and the accepted decimal
  // separators: '.', ',', Arabic decimal '٫' (U+066B).
  static final RegExp _allowed =
      RegExp(r'[0-9٠-٩۰-۹.,٫]');

  /// Formatters for a decimal numeric field: block disallowed characters (incl.
  /// on paste) and cap length so a pasted `1e309`-style flood can't build up.
  static final List<TextInputFormatter> decimalFormatters = [
    FilteringTextInputFormatter.allow(_allowed),
    LengthLimitingTextInputFormatter(12),
  ];

  /// Parse a user-entered number, tolerating Arabic-Indic/Persian digits and
  /// Arabic/comma decimal separators. Returns `null` for empty, unparseable, or
  /// **non-finite** input (never returns Infinity/NaN).
  static double? parseFlexibleNumber(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty) return null;

    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final buf = StringBuffer();
    for (final ch in s.split('')) {
      final ai = arabicIndic.indexOf(ch);
      final fa = persian.indexOf(ch);
      if (ai >= 0) {
        buf.write(ai);
      } else if (fa >= 0) {
        buf.write(fa);
      } else {
        buf.write(ch);
      }
    }
    s = buf.toString()
        .replaceAll('٫', '.') // Arabic decimal separator
        .replaceAll('،', '.') // Arabic comma
        .replaceAll(',', '.');

    final v = double.tryParse(s);
    if (v == null || !v.isFinite) return null;
    return v;
  }
}
