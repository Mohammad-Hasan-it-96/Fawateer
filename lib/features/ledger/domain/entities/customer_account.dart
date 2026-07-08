import 'package:equatable/equatable.dart';

import 'customer.dart';

/// A customer plus their derived account summary (balance, activity). Used by
/// the customers list so each row shows what's owed without an extra query.
class CustomerAccount extends Equatable {
  final Customer customer;

  /// Positive = the customer owes the shop; negative = the shop owes them;
  /// zero = settled.
  final double balance;

  final int entryCount;
  final DateTime? lastEntryAt;

  const CustomerAccount({
    required this.customer,
    required this.balance,
    this.entryCount = 0,
    this.lastEntryAt,
  });

  bool get isSettled => balance.abs() < 0.005;

  @override
  List<Object?> get props => [customer, balance, entryCount, lastEntryAt];
}
