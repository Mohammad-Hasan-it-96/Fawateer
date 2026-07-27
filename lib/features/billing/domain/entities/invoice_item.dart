import 'package:equatable/equatable.dart';

class InvoiceItem extends Equatable {
  final int? id;
  final String invoiceId;
  final String productId;
  final String productName;
  final double price; // resolved SP unit price (settlement value)
  final double cost; // snapshot of product cost (SP) at sale time (profit reports)
  final double quantity; // double so weight/fractional sales can be recorded

  // Dual-currency snapshot (display/audit only). For an SP-native line these are
  // 'sp' / 0 / same-as-price; for a USD line they preserve "$X at rate R".
  final String priceCurrency; // PriceCurrency name the line was sold in
  final double fxRate; // SP-per-USD rate used (0 for SP-native)
  final double priceOriginal; // unit price in its original currency
  final double discount; // manual per-line discount in SP (0 = none)

  /// Snapshot of the product's printable custom fields (Plan 010) at sale time,
  /// as a JSON object of resolved `{label: value}` pairs ('' = none). Frozen
  /// like price/cost/fxRate, so a reprint shows the same attributes even if the
  /// product or its field definitions later change.
  final String attributesSnapshot;

  /// How this line was sold — a [ProductSaleType] **name** ('piece'/'weight'),
  /// frozen at sale time (Plan 011 #10). `''` means a legacy row saved before
  /// the snapshot existed; callers fall back to [inferredIsMeasured] for those.
  final String saleType;

  /// The IMEI/serial of the physical unit this line sold (Plan 012), frozen at
  /// sale time; `''` for a non-serialized product. Kept on the line — not just
  /// on the unit row — so a reprint still shows the serial even if the unit is
  /// later deleted, the same reprint-eternal rule as the fields above.
  final String serialSnapshot;

  const InvoiceItem({
    this.id,
    required this.invoiceId,
    required this.productId,
    required this.productName,
    required this.price,
    this.cost = 0,
    required this.quantity,
    this.priceCurrency = 'sp',
    this.fxRate = 0,
    this.priceOriginal = 0,
    this.discount = 0,
    this.attributesSnapshot = '',
    this.saleType = '',
    this.serialSnapshot = '',
  });

  /// Whether this line was sold by measure (weight), for unit display on the
  /// invoice table and reprinted receipts.
  ///
  /// Prefers the [saleType] snapshot. Falls back — only for legacy rows saved
  /// before that column existed — to the old heuristic: a fractional quantity
  /// means a weighed sale. That guess mislabels a whole-number weight sale
  /// (2.0 kg reads as pieces), which is exactly why the snapshot was added; it
  /// stays only so old invoices are no worse than they were.
  bool get isMeasured => saleType.isEmpty
      ? quantity != quantity.roundToDouble()
      : saleType == 'weight';

  /// Line subtotal before the discount.
  double get gross => price * quantity;

  /// Line total after the per-line discount (never negative).
  double get total => (gross - discount).clamp(0, double.infinity).toDouble();

  @override
  List<Object?> get props => [
        id,
        invoiceId,
        productId,
        productName,
        price,
        cost,
        quantity,
        priceCurrency,
        fxRate,
        priceOriginal,
        discount,
        attributesSnapshot,
        saleType,
        serialSnapshot,
      ];
}
