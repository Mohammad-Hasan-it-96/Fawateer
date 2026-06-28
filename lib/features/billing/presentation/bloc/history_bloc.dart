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

  HistoryBloc({required this.repository}) : super(const HistoryState()) {
    on<LoadHistoryEvent>(_onLoadHistory);
    on<LoadInvoiceDetailsEvent>(_onLoadInvoiceDetails);
  }

  /// Subscribe to the invoice stream. Dispatched once at startup; the list and
  /// today's totals then refresh automatically after every sale — no manual
  /// reload needed.
  Future<void> _onLoadHistory(
      LoadHistoryEvent event, Emitter<HistoryState> emit) async {
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
        );
      },
      onError: (e, _) =>
          state.copyWith(status: HistoryStatus.error, error: e.toString()),
    );
  }

  Future<void> _onLoadInvoiceDetails(
      LoadInvoiceDetailsEvent event, Emitter<HistoryState> emit) async {
    if (state.itemsCache.containsKey(event.invoiceId)) return;

    final result = await repository.getInvoiceItems(event.invoiceId);
    result.fold(
      (_) {}, // silently ignore errors for item loading
      (items) {
        final updated = Map<String, List<InvoiceItem>>.from(state.itemsCache);
        updated[event.invoiceId] = items;
        emit(state.copyWith(itemsCache: updated));
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
