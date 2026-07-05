import 'package:equatable/equatable.dart';

/// A single movement on a customer's account.
enum LedgerEntryType {
  /// The customer owes more (a debt / sale on credit) — counts as +amount.
  charge,

  /// The customer paid — counts as −amount.
  payment,
}

class LedgerEntry extends Equatable {
  final String id;
  final String customerId;

  /// Set when auto-created by a credit sale (links to the invoice); else null.
  final String? invoiceId;

  final LedgerEntryType type;

  /// Always positive; the sign comes from [type].
  final double amount;

  final String note;
  final DateTime createdAt;

  const LedgerEntry({
    required this.id,
    required this.customerId,
    this.invoiceId,
    required this.type,
    required this.amount,
    this.note = '',
    required this.createdAt,
  });

  /// +amount for a charge, −amount for a payment.
  double get signedAmount =>
      type == LedgerEntryType.charge ? amount : -amount;

  bool get isFromSale => invoiceId != null;

  @override
  List<Object?> get props =>
      [id, customerId, invoiceId, type, amount, note, createdAt];
}
