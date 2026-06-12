import 'package:equatable/equatable.dart';

class Debt extends Equatable {
  final String id;
  final String customerId;
  final double amount;
  final DateTime date;
  final String notes;

  const Debt({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.date,
    this.notes = '',
  });

  @override
  List<Object?> get props => [id, customerId, amount, date, notes];
}

