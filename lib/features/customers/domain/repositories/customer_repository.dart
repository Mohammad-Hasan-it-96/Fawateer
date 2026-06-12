import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/customer.dart';
import '../entities/debt.dart';

abstract class CustomerRepository {
  Future<Either<Failure, List<Customer>>> getAllCustomers();
  Future<Either<Failure, Customer?>> getCustomerById(String id);
  Future<Either<Failure, void>> saveCustomer(Customer customer);
  Future<Either<Failure, void>> deleteCustomer(String id);

  Future<Either<Failure, List<Debt>>> getAllDebts();
  Future<Either<Failure, List<Debt>>> getDebtsForCustomer(String customerId);
  Future<Either<Failure, void>> saveDebt(Debt debt);
  Future<Either<Failure, void>> deleteDebt(String id);
}

