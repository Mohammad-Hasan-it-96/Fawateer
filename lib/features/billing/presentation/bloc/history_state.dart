part of 'history_bloc.dart';

enum HistoryStatus { initial, loading, loaded, error }

/// A localizable history error. The BLoC sets the case; the page maps it to a
/// translated string — no user-facing English lives in the BLoC.
enum HistoryError { loadFailed }

class HistoryState extends Equatable {
  final HistoryStatus status;
  final List<Invoice> invoices;
  final Map<String, List<InvoiceItem>> itemsCache;
  final HistoryError? error;

  /// Invoice IDs whose line-item load failed, so the UI can show a retry hint
  /// instead of an endless spinner. Cleared for an invoice once its items load.
  final Set<String> failedItems;
  final double todayTotal;
  final int todayCount;

  const HistoryState({
    this.status = HistoryStatus.initial,
    this.invoices = const [],
    this.itemsCache = const {},
    this.error,
    this.failedItems = const {},
    this.todayTotal = 0,
    this.todayCount = 0,
  });

  HistoryState copyWith({
    HistoryStatus? status,
    List<Invoice>? invoices,
    Map<String, List<InvoiceItem>>? itemsCache,
    HistoryError? error,
    bool clearError = false,
    Set<String>? failedItems,
    double? todayTotal,
    int? todayCount,
  }) {
    return HistoryState(
      status: status ?? this.status,
      invoices: invoices ?? this.invoices,
      itemsCache: itemsCache ?? this.itemsCache,
      error: clearError ? null : (error ?? this.error),
      failedItems: failedItems ?? this.failedItems,
      todayTotal: todayTotal ?? this.todayTotal,
      todayCount: todayCount ?? this.todayCount,
    );
  }

  @override
  List<Object?> get props => [
        status,
        invoices,
        itemsCache,
        error,
        failedItems,
        todayTotal,
        todayCount,
      ];
}
