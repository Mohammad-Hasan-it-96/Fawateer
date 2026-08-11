part of 'history_bloc.dart';

enum HistoryStatus { initial, loading, loaded, error }

/// A localizable history error. The BLoC sets the case; the page maps it to a
/// translated string — no user-facing English lives in the BLoC.
enum HistoryError { loadFailed }

/// One-shot outcome of a reprint, mapped to an ARB string in the page.
enum ReprintStatus { idle, printing, done, failed }

/// Outcome of a delete (Plan 016 A). `done` is what tells the detail page to
/// close itself — the invoice it is showing no longer exists.
enum DeleteStatus { idle, deleting, done, failed }

/// Outcome of a payment-type/customer correction (Plan 016 C-a). Unlike a
/// delete, `done` does **not** close the detail page — the sale is still there,
/// only the way it was paid has been fixed.
enum PaymentChangeStatus { idle, saving, done, failed }

class HistoryState extends Equatable {
  final HistoryStatus status;

  /// The active query (date range, payment, sort, search).
  final SalesFilter filter;

  /// The current list window (first N rows for the filter; grows on LoadMore).
  final List<InvoiceListItem> invoices;

  /// Aggregate totals for the filtered set (drives the summary cards).
  final SalesSummary summary;

  /// Whether the window might have more rows to page in.
  final bool hasMore;

  /// A page load is in flight (shows a footer spinner).
  final bool loadingMore;

  /// Line items per invoice, lazy-loaded for the detail page.
  final Map<String, List<InvoiceItem>> itemsCache;

  /// Invoice IDs whose line-item load failed, so the UI can show a retry hint.
  final Set<String> failedItems;

  final HistoryError? error;

  /// Transient reprint outcome + which invoice it applies to.
  final ReprintStatus reprintStatus;
  final String? reprintingId;

  /// Transient delete outcome.
  final DeleteStatus deleteStatus;

  /// Transient payment-correction outcome.
  final PaymentChangeStatus paymentChangeStatus;

  const HistoryState({
    this.status = HistoryStatus.initial,
    required this.filter,
    this.invoices = const [],
    this.summary = const SalesSummary(),
    this.hasMore = false,
    this.loadingMore = false,
    this.itemsCache = const {},
    this.failedItems = const {},
    this.error,
    this.reprintStatus = ReprintStatus.idle,
    this.reprintingId,
    this.deleteStatus = DeleteStatus.idle,
    this.paymentChangeStatus = PaymentChangeStatus.idle,
  });

  HistoryState copyWith({
    HistoryStatus? status,
    SalesFilter? filter,
    List<InvoiceListItem>? invoices,
    SalesSummary? summary,
    bool? hasMore,
    bool? loadingMore,
    Map<String, List<InvoiceItem>>? itemsCache,
    Set<String>? failedItems,
    HistoryError? error,
    bool clearError = false,
    ReprintStatus? reprintStatus,
    String? reprintingId,
    bool clearReprintingId = false,
    DeleteStatus? deleteStatus,
    PaymentChangeStatus? paymentChangeStatus,
  }) {
    return HistoryState(
      status: status ?? this.status,
      filter: filter ?? this.filter,
      invoices: invoices ?? this.invoices,
      summary: summary ?? this.summary,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      itemsCache: itemsCache ?? this.itemsCache,
      failedItems: failedItems ?? this.failedItems,
      error: clearError ? null : (error ?? this.error),
      reprintStatus: reprintStatus ?? this.reprintStatus,
      reprintingId: clearReprintingId ? null : (reprintingId ?? this.reprintingId),
      deleteStatus: deleteStatus ?? this.deleteStatus,
      paymentChangeStatus: paymentChangeStatus ?? this.paymentChangeStatus,
    );
  }

  @override
  List<Object?> get props => [
        status,
        filter,
        invoices,
        summary,
        hasMore,
        loadingMore,
        itemsCache,
        failedItems,
        error,
        reprintStatus,
        reprintingId,
        deleteStatus,
        paymentChangeStatus,
      ];
}
