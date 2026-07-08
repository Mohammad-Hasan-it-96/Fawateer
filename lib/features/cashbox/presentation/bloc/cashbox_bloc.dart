import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/cash_transaction.dart';
import '../../domain/entities/cash_transaction_type.dart';
import '../../domain/repositories/cashbox_repository.dart';

part 'cashbox_event.dart';
part 'cashbox_state.dart';

/// The cashbox: streams every cash transaction and derives the current balance
/// plus today's cash-in / cash-out in-BLoC (the balance is never stored). Add/
/// delete emit only transient feedback — the list refreshes from the stream.
class CashboxBloc extends Bloc<CashboxEvent, CashboxState> {
  final CashboxRepository repository;
  bool _watching = false;

  CashboxBloc({required this.repository}) : super(const CashboxState()) {
    on<LoadCashbox>(_onLoad);
    on<AddCashTransaction>(_onAdd);
    on<DeleteCashTransaction>(_onDelete);
    on<ChangeCashboxFilter>(_onChangeFilter);
  }

  static double _round(double v) => (v * 100).roundToDouble() / 100;

  Future<void> _onLoad(LoadCashbox event, Emitter<CashboxState> emit) async {
    if (_watching) return;
    _watching = true;
    emit(state.copyWith(status: CashboxStatus.loading));

    await emit.forEach(
      repository.watchTransactions(),
      onData: (txs) {
        final now = DateTime.now();
        final dayStart = DateTime(now.year, now.month, now.day);
        final dayEnd = dayStart.add(const Duration(days: 1));

        double balance = 0, inSum = 0, outSum = 0;
        for (final t in txs) {
          balance += t.amount;
          final isToday = !t.occurredAt.isBefore(dayStart) &&
              t.occurredAt.isBefore(dayEnd);
          if (isToday) {
            if (t.amount >= 0) {
              inSum += t.amount;
            } else {
              outSum += -t.amount;
            }
          }
        }
        return state.copyWith(
          status: CashboxStatus.loaded,
          transactions: txs,
          balance: _round(balance),
          todayIn: _round(inSum),
          todayOut: _round(outSum),
        );
      },
      onError: (_, __) => state.copyWith(
          status: CashboxStatus.error, message: CashboxMessage.loadFailed),
    );
  }

  Future<void> _onAdd(
      AddCashTransaction event, Emitter<CashboxState> emit) async {
    final result = await repository.addTransaction(event.transaction);
    result.fold(
      (_) => emit(state.copyWith(message: CashboxMessage.saveFailed)),
      (_) => emit(state.copyWith(message: CashboxMessage.transactionAdded)),
    );
  }

  Future<void> _onDelete(
      DeleteCashTransaction event, Emitter<CashboxState> emit) async {
    // System-generated entries (cash sale, debt payment) are owned by their
    // source record — they can only be reversed by deleting that source.
    final match = state.transactions
        .where((t) => t.id == event.id)
        .cast<CashTransaction?>()
        .firstWhere((_) => true, orElse: () => null);
    if (match != null && match.isSystemGenerated) {
      emit(state.copyWith(message: CashboxMessage.deleteNotAllowed));
      return;
    }
    final result = await repository.deleteTransaction(event.id);
    result.fold(
      (_) => emit(state.copyWith(message: CashboxMessage.saveFailed)),
      (_) => emit(state.copyWith(message: CashboxMessage.transactionDeleted)),
    );
  }

  void _onChangeFilter(
      ChangeCashboxFilter event, Emitter<CashboxState> emit) {
    emit(state.copyWith(
      filterType: event.filterType,
      rangeStart: event.rangeStart,
      rangeEnd: event.rangeEnd,
      typeFilter: event.typeFilter,
    ));
  }
}
