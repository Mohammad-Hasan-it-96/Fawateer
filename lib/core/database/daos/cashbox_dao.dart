import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/cashbox_transactions_table.dart';

part 'cashbox_dao.g.dart';

@DriftAccessor(tables: [CashboxTransactions])
class CashboxDao extends DatabaseAccessor<AppDatabase> with _$CashboxDaoMixin {
  CashboxDao(super.db);

  /// All transactions, newest first (reactive).
  Stream<List<CashboxTransactionRow>> watchTransactions() =>
      (select(cashboxTransactions)
            ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
          .watch();

  Future<void> insertTransaction(CashboxTransactionsCompanion tx) =>
      into(cashboxTransactions).insert(tx);

  Future<int> deleteTransaction(String id) =>
      (delete(cashboxTransactions)..where((t) => t.id.equals(id))).go();

  /// Remove any cashbox entry linked to a source record (invoice / ledger
  /// entry) — used when that source is deleted, so the derived balance stays
  /// honest. No-op when the source had no cashbox entry (e.g. a credit sale).
  Future<int> deleteByRelatedId(String relatedId) =>
      (delete(cashboxTransactions)..where((t) => t.relatedId.equals(relatedId)))
          .go();

  /// Reactive derived balance = signed sum of every transaction. Simpler than
  /// the ledger's `SUM(CASE …)` because the sign already lives in `amount`.
  Stream<double> watchBalance() => customSelect(
        'SELECT COALESCE(SUM(amount), 0.0) AS balance FROM cashbox_transactions',
        readsFrom: {cashboxTransactions},
      ).watchSingle().map((r) => (r.data['balance'] as num).toDouble());
}
