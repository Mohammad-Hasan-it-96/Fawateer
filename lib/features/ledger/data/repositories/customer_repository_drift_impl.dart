import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/customers_dao.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/sync/sync_clock.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_account.dart';
import '../../domain/repositories/customer_repository.dart';

class CustomerRepositoryDriftImpl implements CustomerRepository {
  final CustomersDao _dao;
  final SyncClock _clock;

  const CustomerRepositoryDriftImpl(this._dao, this._clock);

  static Customer _toEntity(CustomerRow r) => Customer(
        id: r.id,
        name: r.name,
        phone: r.phone,
        note: r.note,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
        isArchived: r.isArchived,
      );

  static CustomersCompanion _toCompanion(Customer c, SyncStamp stamp) =>
      CustomersCompanion(
        id: Value(c.id),
        name: Value(c.name),
        phone: Value(c.phone),
        note: Value(c.note),
        createdAt: Value(c.createdAt.millisecondsSinceEpoch),
        isArchived: Value(c.isArchived),

        // **The sync stamp, on every write.** Without it `updated_at` stays ''
        // — the "predates sync, never push me" marker — so the row is silently
        // invisible to `SyncDao.collectSince` and never leaves this phone. That
        // was the shipped state: deletes and sales were stamped, ordinary
        // creates and edits were not, so a shop could add a product on one till
        // and watch the other till never hear about it while every screen
        // reported success (found in a two-phone field test, 2026-09-01).
        updatedAt: Value(stamp.hlc),
        originDevice: Value(stamp.device),
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
      await _dao.upsertCustomer(
          _toCompanion(customer, await _clock.stamp()));
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
      await _dao.upsertCustomer(
          _toCompanion(customer, await _clock.stamp()));
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
      await _dao.softDeleteCustomer(id, await _clock.stamp());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
