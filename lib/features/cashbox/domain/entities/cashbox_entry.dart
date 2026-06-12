import 'package:equatable/equatable.dart';

class CashboxEntry extends Equatable {
  final int? id;
  final double amount;

  /// 'income' or 'expense'
  final String type;
  final DateTime date;
  final String notes;

  const CashboxEntry({
    this.id,
    required this.amount,
    required this.type,
    required this.date,
    this.notes = '',
  });

  @override
  List<Object?> get props => [id, amount, type, date, notes];
}

