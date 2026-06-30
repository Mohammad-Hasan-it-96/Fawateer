/// Formats a quantity for display. Whole numbers print with no decimals (`3`);
/// fractional / weight values keep up to 3 trailing decimals, trimmed (`0.5`,
/// `1.25`). Shared by the cart UI, checkout, and printed receipts so a sold
/// quantity reads the same everywhere.
String formatQty(num q) {
  if (q == q.truncateToDouble()) return q.toStringAsFixed(0);
  return q
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
