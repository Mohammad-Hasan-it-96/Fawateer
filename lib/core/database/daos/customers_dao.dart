import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/customers_table.dart';

part 'customers_dao.g.dart';

@DriftAccessor(tables: [Customers])
class CustomersDao extends DatabaseAccessor<AppDatabase>
    with _$CustomersDaoMixin {
  CustomersDao(super.db);

  Future<List<CustomerRow>> getAllCustomers() => select(customers).get();

  Stream<List<CustomerRow>> watchAllCustomers() => select(customers).watch();

  Future<CustomerRow?> getById(String id) =>
      (select(customers)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// Insert or replace.
  Future<void> insertCustomer(CustomersCompanion customer) =>
      into(customers).insert(customer, mode: InsertMode.insertOrReplace);

  Future<int> deleteCustomer(String id) =>
      (delete(customers)..where((c) => c.id.equals(id))).go();
}

