import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/customers_dao.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_account.dart';
import '../../domain/repositories/customer_repository.dart';

class CustomerRepositoryDriftImpl implements CustomerRepository {
  final CustomersDao _dao;

  const CustomerRepositoryDriftImpl(this._dao);

  static Customer _toEntity(CustomerRow r) => Customer(
        id: r.id,
        name: r.name,
        phone: r.phone,
        note: r.note,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
        isArchived: r.isArchived,
      );

  static CustomersCompanion _toCompanion(Customer c) => CustomersCompanion(
        id: Value(c.id),
        name: Value(c.name),
        phone: Value(c.phone),
        note: Value(c.note),
        createdAt: Value(c.createdAt.millisecondsSinceEpoch),
        isArchived: Value(c.isArchived),
      );

  @override
  Stream<List<CustomerAccount>> watchCustomers() =>
      _dao.watchCustomersWithBalance().map((rows) => rows
          .map((r) => CustomerAccount(
                customer: Customer(
                  id: r.id,
                  name: r.name,
                  phone: r.phone,
                  note: r.note,
                  createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
                ),
                balance: r.balance,
                entryCount: r.entryCount,
                lastEntryAt: r.lastEntryAt == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(r.lastEntryAt!),
              ))
          .toList());

  @override
  Stream<Customer?> watchCustomer(String id) =>
      _dao.watchCustomer(id).map((r) => r == null ? null : _toEntity(r));

  @override
  Future<Either<Failure, Customer>> getCustomer(String id) async {
    try {
      final row = await _dao.getCustomer(id);
      if (row == null) return Left(NotFoundFailure('No customer: $id'));
      return Right(_toEntity(row));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addCustomer(Customer customer) async {
    try {
      if (await _dao.nameExists(customer.name, exceptId: customer.id)) {
        return const Left(DuplicateFailure('Duplicate customer name'));
      }
      await _dao.upsertCustomer(_toCompanion(customer));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomer(Customer customer) async {
    try {
      if (await _dao.nameExists(customer.name, exceptId: customer.id)) {
        return const Left(DuplicateFailure('Duplicate customer name'));
      }
      await _dao.upsertCustomer(_toCompanion(customer));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    try {
      // Guard: never silently discard ledger history.
      if (await _dao.countEntries(id) > 0) {
        return const Left(
            ConflictFailure('Customer still has ledger entries'));
      }
      await _dao.deleteCustomer(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
