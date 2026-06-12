import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/usecases/invoice_usecases.dart';
import '../../../../core/usecase/usecase.dart';

part 'history_event.dart';
part 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetAllInvoicesUseCase getAllInvoicesUseCase;
  final GetInvoiceItemsUseCase getInvoiceItemsUseCase;

  HistoryBloc({
    required this.getAllInvoicesUseCase,
    required this.getInvoiceItemsUseCase,
  }) : super(const HistoryState()) {
    on<LoadHistoryEvent>(_onLoadHistory);
    on<LoadInvoiceDetailsEvent>(_onLoadInvoiceDetails);
  }

  Future<void> _onLoadHistory(
      LoadHistoryEvent event, Emitter<HistoryState> emit) async {
    emit(state.copyWith(status: HistoryStatus.loading));

    final result = await getAllInvoicesUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
          status: HistoryStatus.error, error: failure.message)),
      (invoices) {
        final todayStart = DateTime.now();
        final startOfDay =
            DateTime(todayStart.year, todayStart.month, todayStart.day);
        final todayInvoices = invoices
            .where((i) =>
                !i.createdAt.isBefore(startOfDay))
            .toList();
        emit(state.copyWith(
          status: HistoryStatus.loaded,
          invoices: invoices,
          todayTotal: todayInvoices.fold<double>(0.0, (s, i) => s + i.totalAmount),
          todayCount: todayInvoices.length,
        ));
      },
    );
  }

  Future<void> _onLoadInvoiceDetails(
      LoadInvoiceDetailsEvent event, Emitter<HistoryState> emit) async {
    if (state.itemsCache.containsKey(event.invoiceId)) return;

    final result = await getInvoiceItemsUseCase(event.invoiceId);
    result.fold(
      (_) {}, // silently ignore errors for item loading
      (items) {
        final updated = Map<String, List<InvoiceItem>>.from(state.itemsCache);
        updated[event.invoiceId] = items;
        emit(state.copyWith(itemsCache: updated));
      },
    );
  }
}
