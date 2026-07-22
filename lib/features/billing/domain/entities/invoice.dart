import 'package:equatable/equatable.dart';

class Invoice extends Equatable {
  final String id;
  final DateTime createdAt;

  /// Final discounted total the sale settled at (net of line + cart discounts).
  final double totalAmount;

  /// Whole-cart discount in SP applied on top of per-line discounts (0 = none).
  final double invoiceDiscount;

  const Invoice({
    required this.id,
    required this.createdAt,
    required this.totalAmount,
    this.invoiceDiscount = 0,
  });

  @override
  List<Object?> get props => [id, createdAt, totalAmount, invoiceDiscount];
}
