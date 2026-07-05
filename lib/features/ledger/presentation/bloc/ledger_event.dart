part of 'ledger_bloc.dart';

abstract class LedgerEvent extends Equatable {
  const LedgerEvent();
  @override
  List<Object?> get props => [];
}

class LoadLedger extends LedgerEvent {
  final String customerId;
  const LoadLedger(this.customerId);
  @override
  List<Object?> get props => [customerId];
}

class AddLedgerEntry extends LedgerEvent {
  final LedgerEntry entry;
  const AddLedgerEntry(this.entry);
  @override
  List<Object?> get props => [entry];
}

class DeleteLedgerEntry extends LedgerEvent {
  final String id;
  const DeleteLedgerEntry(this.id);
  @override
  List<Object?> get props => [id];
}
