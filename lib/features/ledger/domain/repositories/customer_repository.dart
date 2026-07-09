import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/customer.dart';
import '../entities/customer_account.dart';

abstract class CustomerRepository {
  /// Reactive list of non-archived customers, each with their derived balance.
  Stream<List<CustomerAccount>> watchCustomers();

  Future<Either<Failure, Customer>> getCustomer(String id);

  /// Reactive single customer (null if it doesn't exist / was deleted) — lets a
  /// detail view reflect edits immediately.
  Stream<Customer?> watchCustomer(String id);
  Future<Either<Failure, void>> addCustomer(Customer customer);
  Future<Either<Failure, void>> updateCustomer(Customer customer);

  /// Delete a customer. Returns `Left(ConflictFailure)` when they still have
  /// ledger entries — history is never silently discarded (archive instead).
  Future<Either<Failure, void>> deleteCustomer(String id);
}
