part of 'customer_bloc.dart';

enum CustomerStatus { initial, loading, loaded, error }

/// Localizable feedback; the page maps it to a string so no user-facing English
/// lives in the BLoC.
enum CustomerMessage {
  added,
  updated,
  deleted,
  deleteBlocked,
  saveFailed,
  loadFailed,
}

class CustomerState extends Equatable {
  final CustomerStatus status;
  final List<CustomerAccount> customers;

  /// Transient one-shot feedback; cleared on the next emit unless set.
  final CustomerMessage? message;

  const CustomerState({
    this.status = CustomerStatus.initial,
    this.customers = const [],
    this.message,
  });

  CustomerState copyWith({
    CustomerStatus? status,
    List<CustomerAccount>? customers,
    CustomerMessage? message,
  }) {
    return CustomerState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, customers, message];
}
