import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_account.dart';
import '../../domain/repositories/customer_repository.dart';

part 'customer_event.dart';
part 'customer_state.dart';

/// Customers list + CRUD. Stream-backed (like `ProductBloc`): [LoadCustomers]
/// subscribes once and the list stays live; mutation handlers emit only their
/// transient feedback.
class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository repository;
  bool _watching = false;

  CustomerBloc({required this.repository}) : super(const CustomerState()) {
    on<LoadCustomers>(_onLoad);
    on<AddCustomer>((e, emit) => _runMutation(
        emit, () => repository.addCustomer(e.customer), CustomerMessage.added));
    on<UpdateCustomer>((e, emit) => _runMutation(emit,
        () => repository.updateCustomer(e.customer), CustomerMessage.updated));
    on<DeleteCustomer>(_onDelete);
  }

  Future<void> _onLoad(LoadCustomers event, Emitter<CustomerState> emit) async {
    if (_watching) return;
    _watching = true;
    emit(state.copyWith(status: CustomerStatus.loading));
    await emit.forEach(
      repository.watchCustomers(),
      onData: (customers) => state.copyWith(
          status: CustomerStatus.loaded, customers: customers),
      onError: (_, __) => state.copyWith(
          status: CustomerStatus.error, message: CustomerMessage.loadFailed),
    );
  }

  Future<void> _onDelete(
      DeleteCustomer event, Emitter<CustomerState> emit) async {
    final result = await repository.deleteCustomer(event.id);
    result.fold(
      (failure) => emit(state.copyWith(
        status: CustomerStatus.error,
        message: failure is ConflictFailure
            ? CustomerMessage.deleteBlocked
            : CustomerMessage.saveFailed,
      )),
      (_) => emit(state.copyWith(
          status: CustomerStatus.loaded, message: CustomerMessage.deleted)),
    );
  }

  Future<void> _runMutation(
    Emitter<CustomerState> emit,
    Future<Either<Failure, void>> Function() action,
    CustomerMessage successMessage,
  ) async {
    final result = await action();
    result.fold(
      (_) => emit(state.copyWith(
          status: CustomerStatus.error, message: CustomerMessage.saveFailed)),
      (_) => emit(
          state.copyWith(status: CustomerStatus.loaded, message: successMessage)),
    );
  }
}
