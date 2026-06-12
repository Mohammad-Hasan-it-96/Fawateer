import 'package:equatable/equatable.dart';

class InvoiceItem extends Equatable {
  final int? id;
  final String invoiceId;
  final String productId;
  final String productName;
  final double price;
  final int quantity;

  const InvoiceItem({
    this.id,
    required this.invoiceId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  @override
  List<Object?> get props =>
      [id, invoiceId, productId, productName, price, quantity];
}

