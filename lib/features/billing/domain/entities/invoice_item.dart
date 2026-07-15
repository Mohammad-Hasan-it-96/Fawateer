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
  });

  double get total => price * quantity;

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
      ];
}
