part of 'cashbox_bloc.dart';

enum CashboxStatus { initial, loading, loaded, error }

/// Localizable feedback; the page maps it to a string.
enum CashboxMessage {
  transactionAdded,
  transactionDeleted,
  deleteNotAllowed,
  saveFailed,
  loadFailed,
}

/// The active history filter.
enum CashboxFilterType { all, today, dateRange, type }

class CashboxState extends Equatable {
  final CashboxStatus status;

  /// All transactions, newest first.
  final List<CashTransaction> transactions;

  /// Derived running balance = signed sum of all transactions.
  final double balance;

  /// Today's cash-in / cash-out totals (absolute values).
  final double todayIn;
  final double todayOut;

  final CashboxFilterType filterType;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final CashTransactionType? typeFilter;

  final CashboxMessage? message;

  const CashboxState({
    this.status = CashboxStatus.initial,
    this.transactions = const [],
    this.balance = 0,
    this.todayIn = 0,
    this.todayOut = 0,
    this.filterType = CashboxFilterType.all,
    this.rangeStart,
    this.rangeEnd,
    this.typeFilter,
    this.message,
  });

  /// The transactions to show given the active filter. Pure except the `today`
  /// case, which reads the current day at build time.
  List<CashTransaction> get visibleTransactions {
    switch (filterType) {
      case CashboxFilterType.all:
        return transactions;
      case CashboxFilterType.today:
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day);
        final end = start.add(const Duration(days: 1));
        return transactions
            .where((t) =>
                !t.occurredAt.isBefore(start) && t.occurredAt.isBefore(end))
            .toList();
      case CashboxFilterType.dateRange:
        if (rangeStart == null || rangeEnd == null) return transactions;
        final start = DateTime(
            rangeStart!.year, rangeStart!.month, rangeStart!.day);
        final end = DateTime(rangeEnd!.year, rangeEnd!.month, rangeEnd!.day)
            .add(const Duration(days: 1));
        return transactions
            .where((t) =>
                !t.occurredAt.isBefore(start) && t.occurredAt.isBefore(end))
            .toList();
      case CashboxFilterType.type:
        if (typeFilter == null) return transactions;
        return transactions.where((t) => t.type == typeFilter).toList();
    }
  }

  CashboxState copyWith({
    CashboxStatus? status,
    List<CashTransaction>? transactions,
    double? balance,
    double? todayIn,
    double? todayOut,
    CashboxFilterType? filterType,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    CashTransactionType? typeFilter,
    CashboxMessage? message,
  }) {
    return CashboxState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      balance: balance ?? this.balance,
      todayIn: todayIn ?? this.todayIn,
      todayOut: todayOut ?? this.todayOut,
      filterType: filterType ?? this.filterType,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
      typeFilter: typeFilter ?? this.typeFilter,
      // Intentionally NOT null-coalesced: a one-shot feedback signal that resets
      // to null on the next emit unless explicitly set.
      message: message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        transactions,
        balance,
        todayIn,
        todayOut,
        filterType,
        rangeStart,
        rangeEnd,
        typeFilter,
        message,
      ];
}
