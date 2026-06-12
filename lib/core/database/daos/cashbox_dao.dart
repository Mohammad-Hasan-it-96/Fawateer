import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/cashbox_entries_table.dart';

part 'cashbox_dao.g.dart';

@DriftAccessor(tables: [CashboxEntries])
class CashboxDao extends DatabaseAccessor<AppDatabase> with _$CashboxDaoMixin {
  CashboxDao(super.db);

  /// All entries ordered by newest first.
  Future<List<CashboxRow>> getAllEntries() =>
      (select(cashboxEntries)
            ..orderBy([(e) => OrderingTerm.desc(e.date)]))
          .get();

  Stream<List<CashboxRow>> watchAllEntries() =>
      (select(cashboxEntries)
            ..orderBy([(e) => OrderingTerm.desc(e.date)]))
          .watch();

  Future<void> insertEntry(CashboxEntriesCompanion entry) =>
      into(cashboxEntries).insert(entry);

  Future<int> deleteEntry(int id) =>
      (delete(cashboxEntries)..where((e) => e.id.equals(id))).go();
}

