/// Label prefixing a serialized item's number on a printed receipt (Plan 012).
///
/// Deliberately the **generic** Arabic term, not "IMEI": Fawateer is a general
/// POS, and the same feature serves hardware, appliance and jewellery shops for
/// whom "IMEI" is meaningless jargon. Phones are one case, not the framing.
///
/// Hardcoded rather than localized for the same reason `'كغ'` is — receipts are
/// rendered as an Arabic bitmap regardless of the app's UI locale, and both the
/// sale and the reprint must produce byte-identical text. Defined once here so
/// the two paths can't drift apart.
const String kSerialReceiptLabel = 'الرقم التسلسلي';

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

  /// Owner-defined custom fields flagged *show on receipt* (Plan 010), each a
  /// pre-resolved "label: value" display string. Printed as small sub-lines
  /// under the item. Empty for products with no printable attributes. These are
  /// snapshotted at sale time, so a reprint shows them even if the product or
  /// its field definitions are later edited.
  final List<String> attributes;

  const ReceiptLine({
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
    this.unit = '',
    this.attributes = const [],
  });
}
