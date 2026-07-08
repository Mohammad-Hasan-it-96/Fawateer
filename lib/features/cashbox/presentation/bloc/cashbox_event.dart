part of 'cashbox_bloc.dart';

abstract class CashboxEvent extends Equatable {
  const CashboxEvent();
  @override
  List<Object?> get props => [];
}

/// Start streaming transactions (dispatched once at startup).
class LoadCashbox extends CashboxEvent {
  const LoadCashbox();
}

class AddCashTransaction extends CashboxEvent {
  final CashTransaction transaction;
  const AddCashTransaction(this.transaction);
  @override
  List<Object?> get props => [transaction];
}

class DeleteCashTransaction extends CashboxEvent {
  final String id;
  const DeleteCashTransaction(this.id);
  @override
  List<Object?> get props => [id];
}

/// Change the history filter (Today / date range / type / all).
class ChangeCashboxFilter extends CashboxEvent {
  final CashboxFilterType filterType;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final CashTransactionType? typeFilter;

  const ChangeCashboxFilter(
    this.filterType, {
    this.rangeStart,
    this.rangeEnd,
    this.typeFilter,
  });

  @override
  List<Object?> get props => [filterType, rangeStart, rangeEnd, typeFilter];
}
