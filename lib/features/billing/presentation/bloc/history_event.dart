part of 'history_bloc.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object> get props => [];
}

class LoadHistoryEvent extends HistoryEvent {}

class LoadInvoiceDetailsEvent extends HistoryEvent {
  final String invoiceId;
  const LoadInvoiceDetailsEvent(this.invoiceId);
  @override
  List<Object> get props => [invoiceId];
}
