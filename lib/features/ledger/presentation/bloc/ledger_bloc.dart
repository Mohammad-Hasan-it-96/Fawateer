import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../settings/domain/repositories/printer_repository.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/ledger_repository.dart';

part 'ledger_event.dart';
part 'ledger_state.dart';

/// One customer's account detail: loads the customer, streams their entries, and
/// derives the running balance in-BLoC (no second stream). Add/delete emit only
/// transient feedback — the list refreshes from the stream.
class LedgerBloc extends Bloc<LedgerEvent, LedgerState> {
  final CustomerRepository customerRepository;
  final LedgerRepository ledgerRepository;
  final PrinterRepository printerRepository;
  bool _watching = false;

  LedgerBloc({
    required this.customerRepository,
    required this.ledgerRepository,
    required this.printerRepository,
  }) : super(const LedgerState()) {
    on<LoadLedger>(_onLoad);
    on<AddLedgerEntry>(_onAddEntry);
    on<DeleteLedgerEntry>(_onDeleteEntry);
    on<PrintStatement>(_onPrintStatement);
  }

  Future<void> _onLoad(LoadLedger event, Emitter<LedgerState> emit) async {
    if (_watching) return;
    _watching = true;
    emit(state.copyWith(status: LedgerStatus.loading));

    final customerResult = await customerRepository.getCustomer(event.customerId);
    customerResult.fold(
      (_) {},
      (customer) => emit(state.copyWith(customer: customer)),
    );

    await emit.forEach(
      ledgerRepository.watchEntries(event.customerId),
      onData: (entries) {
        final raw = entries.fold<double>(0, (sum, e) => sum + e.signedAmount);
        final balance = (raw * 100).roundToDouble() / 100;
        return state.copyWith(
            status: LedgerStatus.loaded, entries: entries, balance: balance);
      },
      onError: (_, __) => state.copyWith(
          status: LedgerStatus.error, message: LedgerMessage.loadFailed),
    );
  }

  Future<void> _onAddEntry(
      AddLedgerEntry event, Emitter<LedgerState> emit) async {
    final result = await ledgerRepository.addEntry(event.entry);
    result.fold(
      (_) => emit(state.copyWith(message: LedgerMessage.saveFailed)),
      (_) => emit(state.copyWith(
          message: event.entry.type == LedgerEntryType.payment
              ? LedgerMessage.paymentAdded
              : LedgerMessage.chargeAdded)),
    );
  }

  Future<void> _onDeleteEntry(
      DeleteLedgerEntry event, Emitter<LedgerState> emit) async {
    final result = await ledgerRepository.deleteEntry(event.id);
    result.fold(
      (_) => emit(state.copyWith(message: LedgerMessage.saveFailed)),
      (_) => emit(state.copyWith(message: LedgerMessage.entryDeleted)),
    );
  }

  Future<void> _onPrintStatement(
      PrintStatement event, Emitter<LedgerState> emit) async {
    final printed = await printerRepository.printStatement(event.text);
    emit(state.copyWith(
        message: printed
            ? LedgerMessage.statementPrinted
            : LedgerMessage.printerUnavailable));
  }
}
