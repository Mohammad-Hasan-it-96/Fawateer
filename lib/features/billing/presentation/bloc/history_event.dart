part of 'history_bloc.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object?> get props => [];
}

/// Dispatched once at startup: subscribes the audit list + summary streams with
/// the default filter (today, newest first).
class LoadHistoryEvent extends HistoryEvent {}

/// Replace the active filter (date/payment/sort/search). Resets pagination and
/// re-subscribes both streams. The UI builds the new filter with `SalesFilter`'s
/// `with*` helpers off the current one.
class FilterChanged extends HistoryEvent {
  final SalesFilter filter;
  const FilterChanged(this.filter);
  @override
  List<Object?> get props => [filter];
}

/// Grow the list window by one page (infinite scroll).
class LoadMoreEvent extends HistoryEvent {}

/// Lazy-load a single invoice's line items (for the detail page), cached.
class LoadInvoiceDetailsEvent extends HistoryEvent {
  final String invoiceId;
  const LoadInvoiceDetailsEvent(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
}

/// Reprint a stored invoice's receipt. Carries the shop header/footer (from
/// `ShopBloc` in the UI) and the invoice total, mirroring checkout's
/// `PrintReceiptEvent`.
/// Undo a sale completely (Plan 016 A) — stock, cash drawer and customer debt
/// all reverse with it. The list is stream-backed, so the row disappears on its
/// own; this only reports the outcome.
class DeleteInvoiceEvent extends HistoryEvent {
  final String invoiceId;
  const DeleteInvoiceEvent(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
}

class ReprintInvoiceEvent extends HistoryEvent {
  final String invoiceId;
  final double total;
  final String shopName;
  final String address1;
  final String address2;
  final String phone;
  final String footer;
  final String currency;
  const ReprintInvoiceEvent({
    required this.invoiceId,
    required this.total,
    required this.shopName,
    required this.address1,
    required this.address2,
    required this.phone,
    required this.footer,
    required this.currency,
  });
  @override
  List<Object?> get props =>
      [invoiceId, total, shopName, address1, address2, phone, footer, currency];
}

// ── Internal events (fed from stream subscriptions; not dispatched by the UI) ──

class _InvoicesUpdated extends HistoryEvent {
  final List<InvoiceListItem> invoices;
  const _InvoicesUpdated(this.invoices);
  @override
  List<Object?> get props => [invoices];
}

class _SummaryUpdated extends HistoryEvent {
  final SalesSummary summary;
  const _SummaryUpdated(this.summary);
  @override
  List<Object?> get props => [summary];
}

class _StreamFailed extends HistoryEvent {
  const _StreamFailed();
}
