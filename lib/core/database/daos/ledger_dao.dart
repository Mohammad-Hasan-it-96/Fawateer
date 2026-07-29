import 'package:drift/drift.dart';
import '../../sync/sync_clock.dart';
import '../app_database.dart';
import '../tables/ledger_entries_table.dart';

part 'ledger_dao.g.dart';

@DriftAccessor(tables: [LedgerEntries])
class LedgerDao extends DatabaseAccessor<AppDatabase> with _$LedgerDaoMixin {
  LedgerDao(super.db);

  /// A customer's entries, newest first (reactive).
  Stream<List<LedgerEntryRow>> watchEntries(String customerId) =>
      (select(ledgerEntries)
            ..where((e) =>
                e.customerId.equals(customerId) & e.deletedAt.equals(''))
            ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
          .watch();

  Future<List<LedgerEntryRow>> getEntries(String customerId) =>
      (select(ledgerEntries)
            ..where((e) =>
                e.customerId.equals(customerId) & e.deletedAt.equals(''))
            ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
          .get();

  Future<void> insertEntry(LedgerEntriesCompanion entry) =>
      into(ledgerEntries).insert(entry);

  /// Tombstone one ledger entry. The balance is derived from live rows, so this
  /// removes the entry's contribution exactly as a hard delete used to.
  Future<int> softDeleteEntry(String id, SyncStamp stamp) =>
      (update(ledgerEntries)
            ..where((e) => e.id.equals(id) & e.deletedAt.equals('')))
          .write(LedgerEntriesCompanion(
        deletedAt: Value(stamp.hlc),
        updatedAt: Value(stamp.hlc),
        originDevice: Value(stamp.device),
      ));

  /// Reactive derived balance for one customer (`charge` +, `payment` −).
  Stream<double> watchBalance(String customerId) {
    final query = customSelect(
      "SELECT COALESCE(SUM(CASE WHEN entry_type = 'charge' "
      "THEN amount ELSE -amount END), 0.0) AS balance "
      "FROM ledger_entries WHERE customer_id = ? AND deleted_at = ''",
      variables: [Variable<String>(customerId)],
      readsFrom: {ledgerEntries},
    );
    return query
        .watchSingle()
        .map((r) => (r.data['balance'] as num).toDouble());
  }
}
