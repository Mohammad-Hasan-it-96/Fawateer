import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/ledger_entries_table.dart';

part 'ledger_dao.g.dart';

@DriftAccessor(tables: [LedgerEntries])
class LedgerDao extends DatabaseAccessor<AppDatabase> with _$LedgerDaoMixin {
  LedgerDao(super.db);

  /// A customer's entries, newest first (reactive).
  Stream<List<LedgerEntryRow>> watchEntries(String customerId) =>
      (select(ledgerEntries)
            ..where((e) => e.customerId.equals(customerId))
            ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
          .watch();

  Future<List<LedgerEntryRow>> getEntries(String customerId) =>
      (select(ledgerEntries)
            ..where((e) => e.customerId.equals(customerId))
            ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
          .get();

  Future<void> insertEntry(LedgerEntriesCompanion entry) =>
      into(ledgerEntries).insert(entry);

  Future<int> deleteEntry(String id) =>
      (delete(ledgerEntries)..where((e) => e.id.equals(id))).go();

  /// Reactive derived balance for one customer (`charge` +, `payment` −).
  Stream<double> watchBalance(String customerId) {
    final query = customSelect(
      "SELECT COALESCE(SUM(CASE WHEN entry_type = 'charge' "
      "THEN amount ELSE -amount END), 0.0) AS balance "
      "FROM ledger_entries WHERE customer_id = ?",
      variables: [Variable<String>(customerId)],
      readsFrom: {ledgerEntries},
    );
    return query
        .watchSingle()
        .map((r) => (r.data['balance'] as num).toDouble());
  }
}
