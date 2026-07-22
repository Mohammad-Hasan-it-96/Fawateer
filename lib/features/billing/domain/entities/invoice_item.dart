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
  });

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
      ];
}
