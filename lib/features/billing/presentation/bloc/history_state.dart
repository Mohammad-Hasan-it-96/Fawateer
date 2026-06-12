part of 'history_bloc.dart';

enum HistoryStatus { initial, loading, loaded, error }

class HistoryState extends Equatable {
  final HistoryStatus status;
  final List<Invoice> invoices;
  final Map<String, List<InvoiceItem>> itemsCache;
  final String? error;
  final double todayTotal;
  final int todayCount;

  const HistoryState({
    this.status = HistoryStatus.initial,
    this.invoices = const [],
    this.itemsCache = const {},
    this.error,
    this.todayTotal = 0,
    this.todayCount = 0,
  });

  HistoryState copyWith({
    HistoryStatus? status,
    List<Invoice>? invoices,
    Map<String, List<InvoiceItem>>? itemsCache,
    String? error,
    double? todayTotal,
    int? todayCount,
  }) {
    return HistoryState(
      status: status ?? this.status,
      invoices: invoices ?? this.invoices,
      itemsCache: itemsCache ?? this.itemsCache,
      error: error ?? this.error,
      todayTotal: todayTotal ?? this.todayTotal,
      todayCount: todayCount ?? this.todayCount,
    );
  }

  @override
  List<Object?> get props =>
      [status, invoices, itemsCache, error, todayTotal, todayCount];
}
