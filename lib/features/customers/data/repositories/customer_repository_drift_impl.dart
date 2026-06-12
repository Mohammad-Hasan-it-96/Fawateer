import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/customers_dao.dart';
import '../../../../core/database/daos/debts_dao.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/debt.dart';
import '../../domain/repositories/customer_repository.dart';
class CustomerRepositoryDriftImpl implements CustomerRepository {
  final CustomersDao _customersDao;
  final DebtsDao _debtsDao;
  const CustomerRepositoryDriftImpl(this._customersDao, this._debtsDao);
  @override
  Future<Either<Failure, List<Customer>>> getAllCustomers() async {
    try {
      final rows = await _customersDao.getAllCustomers();
      return Right(rows.map((r) => Customer(id: r.id, name: r.name, phone: r.phone)).toList());
    } catch (e) { return Left(CacheFailure(e.toString())); }
  }
  @override
  Future<Either<Failure, Customer?>> getCustomerById(String id) async {
    try {
      final row = await _customersDao.getById(id);
      return Right(row != null ? Customer(id: row.id, name: row.name, phone: row.phone) : null);
    } catch (e) { return Left(CacheFailure(e.toString())); }
  }
  @override
  Future<Either<Failure, void>> saveCustomer(Customer customer) async {
    try {
      await _customersDao.insertCustomer(CustomersCompanion(
        id: Value(customer.id), name: Value(customer.name), phone: Value(customer.phone)));
      return const Right(null);
    } catch (e) { return Left(CacheFailure(e.toString())); }
  }
  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    try { await _customersDao.deleteCustomer(id); return const Right(null); }
    catch (e) { return Left(CacheFailure(e.toString())); }
  }
  @override
  Future<Either<Failure, List<Debt>>> getAllDebts() async {
    try {
      final rows = await _debtsDao.getAllDebts();
      return Right(rows.map(_toDebt).toList());
    } catch (e) { return Left(CacheFailure(e.toString())); }
  }
  @override
  Future<Either<Failure, List<Debt>>> getDebtsForCustomer(String customerId) async {
    try {
      final rows = await _debtsDao.getDebtsForCustomer(customerId);
      return Right(rows.map(_toDebt).toList());
    } catch (e) { return Left(CacheFailure(e.toString())); }
  }
  @override
  Future<Either<Failure, void>> saveDebt(Debt debt) async {
    try {
      await _debtsDao.insertDebt(DebtsCompanion(
        id: Value(debt.id), customerId: Value(debt.customerId),
        amount: Value(debt.amount), date: Value(debt.date.millisecondsSinceEpoch),
        notes: Value(debt.notes)));
      return const Right(null);
    } catch (e) { return Left(CacheFailure(e.toString())); }
  }
  @override
  Future<Either<Failure, void>> deleteDebt(String id) async {
    try { await _debtsDao.deleteDebt(id); return const Right(null); }
    catch (e) { return Left(CacheFailure(e.toString())); }
  }
  static Debt _toDebt(DebtRow r) => Debt(
    id: r.id, customerId: r.customerId, amount: r.amount,
    date: DateTime.fromMillisecondsSinceEpoch(r.date), notes: r.notes);
}
