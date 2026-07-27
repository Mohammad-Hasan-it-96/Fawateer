import 'package:drift/drift.dart';

import 'sync_meta.dart';

/// A single signed cash movement (single-entry cashbox). The current cash
/// balance is always DERIVED by summing [amount] over all rows — never stored,
/// never hand-edited — so it can't drift out of sync.
///
/// Named `cashbox_transactions`, not `cashbox_entries`: an old `cashbox_entries`
/// table existed pre-v3 and was dropped in the v2→v3 migration; a distinct name
/// avoids any collision.
@DataClassName('CashboxTransactionRow')
class CashboxTransactions extends Table with SyncMeta {
  TextColumn get id => text()();

  /// `CashTransactionType.name` — persisted by name string, never index.
  TextColumn get type => text()();

  /// Signed: `+` = cash in, `−` = cash out. Balance = `SUM(amount)`. Money stays
  /// `double` (app-wide convention), rounded to 2 decimals at write time.
  RealColumn get amount => real()();

  TextColumn get note => text().withDefault(const Constant(''))();

  /// Source link: invoice id (cash sale) or ledger-entry id (debt payment);
  /// null for a manual entry.
  TextColumn get relatedId => text().nullable()();

  /// Transaction (business) date — the Today/date-range filters key off this.
  /// Stored as milliseconds since epoch.
  IntColumn get occurredAt => integer()();

  /// Audit insertion time (milliseconds since epoch).
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
