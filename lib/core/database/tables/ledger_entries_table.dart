import 'package:drift/drift.dart';

import 'sync_meta.dart';

/// A single signed movement on a customer's account (single-entry ledger). The
/// running balance is always DERIVED by summing entries (`charge` as +amount,
/// `payment` as −amount) — never stored on the customer — so it can't drift out
/// of sync.
@DataClassName('LedgerEntryRow')
class LedgerEntries extends Table with SyncMeta {
  TextColumn get id => text()();
  TextColumn get customerId => text()();

  /// Set when this entry was auto-created by a credit sale (links to
  /// `sales_invoices.id`); null for a manual charge or payment.
  TextColumn get invoiceId => text().nullable()();

  /// 'charge' (customer owes more) or 'payment' (customer paid).
  TextColumn get entryType => text()();

  /// Always positive; the sign comes from [entryType]. Money stays `double`
  /// (app-wide convention), rounded to 2 decimals at write time.
  RealColumn get amount => real()();

  TextColumn get note => text().withDefault(const Constant(''))();

  /// Stored as milliseconds since epoch.
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
