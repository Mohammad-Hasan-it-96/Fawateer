import 'package:intl/intl.dart';

/// Compact money for dashboard tiles: grouped thousands, no decimals (SP is
/// effectively whole-number), symbol as a suffix — reads naturally in RTL.
String moneyCompact(String currency, double value) {
  final n = NumberFormat('#,##0', 'en').format(value.round());
  return currency.isEmpty ? n : '$n $currency';
}

/// Compact quantity: trims to a whole number when integral, else 1 decimal.
String qtyCompact(double value) {
  if (value == value.roundToDouble()) {
    return NumberFormat('#,##0', 'en').format(value);
  }
  return NumberFormat('#,##0.#', 'en').format(value);
}
