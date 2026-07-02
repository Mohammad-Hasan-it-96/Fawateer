import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/repositories/invoice_repository.dart';

part 'history_event.dart';
part 'history_state.dart';

/// Today's total revenue and invoice count, derived from the full invoice list.
class _TodayStats {
  final double total;
  final int count;
  const _TodayStats(this.total, this.count);
}

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final InvoiceRepository repository;

  /// Guards against a second [LoadHistoryEvent] spinning up a duplicate stream
  /// subscription (and duplicate emits).
  bool _watching = false;

  HistoryBloc({required this.repository}) : super(const HistoryState()) {
    on<LoadHistoryEvent>(_onLoadHistory);
    on<LoadInvoiceDetailsEvent>(_onLoadInvoiceDetails);
  }

  /// Subscribe to the invoice stream. Dispatched once at startup; the list and
  /// today's totals then refresh automatically after every sale — no manual
  /// reload needed. A transient stream error emits an error state but keeps the
  /// subscription alive (`emit.forEach` doesn't cancel on error), so the list
  /// self-recovers on the next emission.
  Future<void> _onLoadHistory(
      LoadHistoryEvent event, Emitter<HistoryState> emit) async {
    if (_watching) return;
    _watching = true;
    emit(state.copyWith(status: HistoryStatus.loading));
    await emit.forEach(
      repository.watchInvoices(),
      onData: (invoices) {
        final today = _todayStats(invoices);
        return state.copyWith(
          status: HistoryStatus.loaded,
          invoices: invoices,
          todayTotal: today.total,
          todayCount: today.count,
          clearError: true,
        );
      },
      onError: (e, _) => state.copyWith(
          status: HistoryStatus.error, error: HistoryError.loadFailed),
    );
  }

  Future<void> _onLoadInvoiceDetails(
      LoadInvoiceDetailsEvent event, Emitter<HistoryState> emit) async {
    if (state.itemsCache.containsKey(event.invoiceId)) return;

    final result = await repository.getInvoiceItems(event.invoiceId);
    result.fold(
      // Record the failure so the card shows a retry hint instead of an endless
      // spinner. Not cached, so re-tapping the card retries the load.
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

  static _TodayStats _todayStats(List<Invoice> invoices) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final today =
        invoices.where((i) => !i.createdAt.isBefore(startOfDay)).toList();
    final total = today.fold<double>(0, (s, i) => s + i.totalAmount);
    return _TodayStats(total, today.length);
  }
}
