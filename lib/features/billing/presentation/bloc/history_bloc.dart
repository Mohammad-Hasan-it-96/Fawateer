import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../settings/domain/entities/receipt_line.dart';
import '../../../settings/domain/repositories/printer_repository.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/entities/invoice_list_item.dart';
import '../../domain/entities/sales_filter.dart';
import '../../domain/entities/sales_summary.dart';
import '../../domain/repositories/invoice_repository.dart';

part 'history_event.dart';
part 'history_state.dart';

/// How many rows the list window grows by per page.
const int _kPageSize = 30;

/// Drives the Sales History / audit center: a filter-driven, paginated list plus
/// a live summary aggregate (both reactive — they re-emit after every sale), the
/// lazy-loaded line items for the detail page, and receipt reprinting.
///
/// The list and summary are kept live via two [StreamSubscription]s that feed
/// **internal** events ([_InvoicesUpdated]/[_SummaryUpdated]) rather than
/// emitting directly (you can't `emit` outside a handler). Changing the filter,
/// or paging in more rows, cancels and re-subscribes with the new query/window.
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final InvoiceRepository repository;
  final PrinterRepository printerRepository;

  StreamSubscription<List<InvoiceListItem>>? _listSub;
  StreamSubscription<SalesSummary>? _summarySub;

  /// Current list-window size; grows by [_kPageSize] on [LoadMoreEvent] and
  /// resets on a filter change.
  int _limit = _kPageSize;

  HistoryBloc({required this.repository, required this.printerRepository})
      : super(HistoryState(filter: SalesFilter.initial())) {
    on<LoadHistoryEvent>(_onLoad);
    on<FilterChanged>(_onFilterChanged);
    on<LoadMoreEvent>(_onLoadMore);
    on<LoadInvoiceDetailsEvent>(_onLoadInvoiceDetails);
    on<ReprintInvoiceEvent>(_onReprint);
    on<_InvoicesUpdated>(_onInvoicesUpdated);
    on<_SummaryUpdated>(_onSummaryUpdated);
    on<_StreamFailed>(_onStreamFailed);
  }

  /// (Re)subscribe the list + summary streams for [state.filter] and [_limit].
  void _resubscribe() {
    _listSub?.cancel();
    _summarySub?.cancel();
    _listSub = repository
        .watchFilteredInvoices(state.filter, limit: _limit)
        .listen(
          (items) => add(_InvoicesUpdated(items)),
          onError: (_) => add(const _StreamFailed()),
        );
    _summarySub = repository.watchSummary(state.filter).listen(
          (summary) => add(_SummaryUpdated(summary)),
          onError: (_) => add(const _StreamFailed()),
        );
  }

  void _onLoad(LoadHistoryEvent event, Emitter<HistoryState> emit) {
    if (_listSub != null) return; // already watching
    emit(state.copyWith(status: HistoryStatus.loading));
    _resubscribe();
  }

  void _onFilterChanged(FilterChanged event, Emitter<HistoryState> emit) {
    _limit = _kPageSize;
    emit(state.copyWith(filter: event.filter, loadingMore: false));
    _resubscribe();
  }

  void _onLoadMore(LoadMoreEvent event, Emitter<HistoryState> emit) {
    if (!state.hasMore || state.loadingMore) return;
    _limit += _kPageSize;
    emit(state.copyWith(loadingMore: true));
    _resubscribe();
  }

  void _onInvoicesUpdated(_InvoicesUpdated event, Emitter<HistoryState> emit) {
    emit(state.copyWith(
      status: HistoryStatus.loaded,
      invoices: event.invoices,
      // If the window came back full, there may be more rows to page in.
      hasMore: event.invoices.length >= _limit,
      loadingMore: false,
      clearError: true,
    ));
  }

  void _onSummaryUpdated(_SummaryUpdated event, Emitter<HistoryState> emit) {
    emit(state.copyWith(summary: event.summary));
  }

  void _onStreamFailed(_StreamFailed event, Emitter<HistoryState> emit) {
    emit(state.copyWith(
      status: HistoryStatus.error,
      error: HistoryError.loadFailed,
      loadingMore: false,
    ));
  }

  Future<void> _onLoadInvoiceDetails(
      LoadInvoiceDetailsEvent event, Emitter<HistoryState> emit) async {
    if (state.itemsCache.containsKey(event.invoiceId)) return;

    final result = await repository.getInvoiceItems(event.invoiceId);
    result.fold(
      // Record the failure so the UI shows a retry hint instead of an endless
      // spinner. Not cached, so re-requesting retries the load.
      (_) => emit(state.copyWith(
          failedItems: {...state.failedItems, event.invoiceId})),
      (items) {
        final updated = Map<String, List<InvoiceItem>>.from(state.itemsCache);
        updated[event.invoiceId] = items;
        final failed =
            state.failedItems.where((id) => id != event.invoiceId).toSet();
        emit(state.copyWith(itemsCache: updated, failedItems: failed));
      },
    );
  }

  /// Reprint a stored invoice. Loads its line items, maps them to
  /// [ReceiptLine]s (no `unit` — `InvoiceItem` doesn't snapshot sale type, so a
  /// weighed line reprints without the "كغ" tag), and prints via the same
  /// [PrinterRepository.printReceipt] the checkout uses. Best-effort: a printer
  /// that's unavailable surfaces [ReprintStatus.failed], never throws.
  Future<void> _onReprint(
      ReprintInvoiceEvent event, Emitter<HistoryState> emit) async {
    if (state.reprintStatus == ReprintStatus.printing) return;
    emit(state.copyWith(
        reprintStatus: ReprintStatus.printing, reprintingId: event.invoiceId));

    final result = await repository.getInvoiceItems(event.invoiceId);
    final lines = result.fold(
      (_) => null,
      (items) => items
          .map((i) => ReceiptLine(
                name: i.productName,
                quantity: i.quantity,
                price: i.price,
                total: i.total,
              ))
          .toList(),
    );

    if (lines == null) {
      emit(state.copyWith(reprintStatus: ReprintStatus.failed));
      emit(state.copyWith(
          reprintStatus: ReprintStatus.idle, clearReprintingId: true));
      return;
    }

    bool ok = false;
    try {
      ok = await printerRepository.printReceipt(
        shopName: event.shopName,
        address1: event.address1,
        address2: event.address2,
        phone: event.phone,
        footer: event.footer,
        currency: event.currency,
        total: event.total,
        items: lines,
      );
    } catch (_) {
      ok = false;
    }
    emit(state.copyWith(
        reprintStatus: ok ? ReprintStatus.done : ReprintStatus.failed));
    emit(state.copyWith(
        reprintStatus: ReprintStatus.idle, clearReprintingId: true));
  }

  @override
  Future<void> close() {
    _listSub?.cancel();
    _summarySub?.cancel();
    return super.close();
  }
}
