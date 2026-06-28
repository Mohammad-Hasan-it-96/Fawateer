import 'package:equatable/equatable.dart';

class InvoiceItem extends Equatable {
  final int? id;
  final String invoiceId;
  final String productId;
  final String productName;
  final double price;
  final double cost; // snapshot of product cost at sale time (profit reports)
  final double quantity; // double so weight/fractional sales can be recorded

  const InvoiceItem({
    this.id,
    required this.invoiceId,
    required this.productId,
    required this.productName,
    required this.price,
    this.cost = 0,
    required this.quantity,
  });

  double get total => price * quantity;

  @override
  List<Object?> get props =>
      [id, invoiceId, productId, productName, price, cost, quantity];
}

