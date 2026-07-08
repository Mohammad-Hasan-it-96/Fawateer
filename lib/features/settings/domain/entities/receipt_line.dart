/// A single printable line on a receipt. Keeps the printer repository free of
/// any cart/invoice types — callers map their data into these.
class ReceiptLine {
  final String name;
  final double quantity;
  final double price;
  final double total;

  /// Unit label for the quantity (e.g. "كغ" for weighed items); empty for plain
  /// piece counts. Printed as "{qty} {unit} × {name}".
  final String unit;

  const ReceiptLine({
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
    this.unit = '',
  });
}
