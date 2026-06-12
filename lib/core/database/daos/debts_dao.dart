import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/debts_table.dart';

part 'debts_dao.g.dart';

@DriftAccessor(tables: [Debts])
class DebtsDao extends DatabaseAccessor<AppDatabase> with _$DebtsDaoMixin {
  DebtsDao(super.db);

  Future<List<DebtRow>> getAllDebts() => select(debts).get();

  Future<List<DebtRow>> getDebtsForCustomer(String customerId) =>
      (select(debts)..where((d) => d.customerId.equals(customerId))).get();

  Stream<List<DebtRow>> watchDebtsForCustomer(String customerId) =>
      (select(debts)..where((d) => d.customerId.equals(customerId))).watch();

  /// Insert or replace.
  Future<void> insertDebt(DebtsCompanion debt) =>
      into(debts).insert(debt, mode: InsertMode.insertOrReplace);

  Future<int> deleteDebt(String id) =>
      (delete(debts)..where((d) => d.id.equals(id))).go();
}

