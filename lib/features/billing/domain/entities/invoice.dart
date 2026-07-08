import 'package:equatable/equatable.dart';

class Invoice extends Equatable {
  final String id;
  final DateTime createdAt;
  final double totalAmount;

  const Invoice({
    required this.id,
    required this.createdAt,
    required this.totalAmount,
  });

  @override
  List<Object?> get props => [id, createdAt, totalAmount];
}
