part of 'ledger_bloc.dart';

enum LedgerStatus { initial, loading, loaded, error }

/// Localizable feedback; the page maps it to a string.
enum LedgerMessage {
  chargeAdded,
  paymentAdded,
  entryDeleted,
  statementPrinted,
  printerUnavailable,
  saveFailed,
  loadFailed,
}

class LedgerState extends Equatable {
  final LedgerStatus status;
  final Customer? customer;
  final List<LedgerEntry> entries;

  /// Derived running balance (positive = customer owes the shop).
  final double balance;

  final LedgerMessage? message;

  const LedgerState({
    this.status = LedgerStatus.initial,
    this.customer,
    this.entries = const [],
    this.balance = 0,
    this.message,
  });

  LedgerState copyWith({
    LedgerStatus? status,
    Customer? customer,
    List<LedgerEntry>? entries,
    double? balance,
    LedgerMessage? message,
  }) {
    return LedgerState(
      status: status ?? this.status,
      customer: customer ?? this.customer,
      entries: entries ?? this.entries,
      balance: balance ?? this.balance,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, customer, entries, balance, message];
}
