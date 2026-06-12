import 'package:equatable/equatable.dart';

class PurchaseItem extends Equatable {
  final int? id;
  final String invoiceId;
  final String productId;
  final String productName;
  final double cost;
  final int quantity;

  const PurchaseItem({
    this.id,
    required this.invoiceId,
    required this.productId,
    required this.productName,
    required this.cost,
    required this.quantity,
  });

  double get total => cost * quantity;

  @override
  List<Object?> get props =>
      [id, invoiceId, productId, productName, cost, quantity];
}

