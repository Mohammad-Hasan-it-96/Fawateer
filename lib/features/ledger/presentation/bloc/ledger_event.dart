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

/// Internal: emitted from the customer stream so a live edit (rename) updates
/// the detail view immediately.
class _CustomerChanged extends LedgerEvent {
  final Customer? customer;
  const _CustomerChanged(this.customer);
  @override
  List<Object?> get props => [customer];
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

/// Print the given (pre-formatted, localized) statement text on the thermal
/// printer. The page builds the text so no user-facing strings live in the BLoC.
class PrintStatement extends LedgerEvent {
  final String text;
  const PrintStatement(this.text);
  @override
  List<Object?> get props => [text];
}
