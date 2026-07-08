import 'package:equatable/equatable.dart';

import 'cash_transaction_type.dart';

/// A single cash movement. The cashbox balance is always DERIVED by summing
/// these ([amount] is signed), never stored — so it can't drift out of sync.
class CashTransaction extends Equatable {
  final String id;
  final CashTransactionType type;

  /// Signed: `+` = cash in, `−` = cash out. Rounded to 2 decimals at write time.
  final double amount;

  final String note;

  /// Source link when auto-created: invoice id (cash sale) or ledger-entry id
  /// (debt payment). Null for a manual entry.
  final String? relatedId;

  /// The transaction (business) date — what the Today / date-range filters use.
  final DateTime occurredAt;

  /// Audit insertion time; usually equal to [occurredAt].
  final DateTime createdAt;

  const CashTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.note = '',
    this.relatedId,
    required this.occurredAt,
    required this.createdAt,
  });

  bool get isInflow => amount >= 0;

  /// Absolute amount (for display; sign is conveyed via colour/label).
  double get magnitude => amount.abs();

  bool get isSystemGenerated => type.isSystemGenerated;

  @override
  List<Object?> get props =>
      [id, type, amount, note, relatedId, occurredAt, createdAt];
}
