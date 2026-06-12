import 'package:equatable/equatable.dart';

class Invoice extends Equatable {
  final String id;
  final DateTime createdAt;
  final double totalAmount;
  final String? customerId;
  final String customerName;

  const Invoice({
    required this.id,
    required this.createdAt,
    required this.totalAmount,
    this.customerId,
    this.customerName = '',
  });

  @override
  List<Object?> get props =>
      [id, createdAt, totalAmount, customerId, customerName];
}

