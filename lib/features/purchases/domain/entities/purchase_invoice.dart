import 'package:equatable/equatable.dart';

class PurchaseInvoice extends Equatable {
  final String id;
  final DateTime createdAt;
  final double totalAmount;
  final String supplier;

  const PurchaseInvoice({
    required this.id,
    required this.createdAt,
    required this.totalAmount,
    this.supplier = '',
  });

  @override
  List<Object?> get props => [id, createdAt, totalAmount, supplier];
}

