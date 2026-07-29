/// Which tables replicate, and how a row in each is identified across devices
/// (Plan 002, Phase 1).
///
/// One list, consulted by both the collector and the applier, so a table can
/// never be pushed but not applied (or vice versa) — the kind of asymmetry that
/// shows up as "my sales reach the other phone but its sales never reach mine"
/// and is almost impossible to spot by reading either side alone.
library;

/// A replicated table and the column that identifies its rows *between* devices.
class SyncTableSpec {
  /// SQLite table name (snake_case, as Drift emits it).
  final String table;

  /// The column two devices agree on. Almost always `id` — the app mints v4
  /// UUIDs client-side, so two devices independently creating rows never
  /// collide.
  final String syncId;

  /// Columns that are meaningful only on the device that wrote them and must be
  /// stripped from an inbound payload.
  final Set<String> localOnly;

  const SyncTableSpec(this.table, {this.syncId = 'id', this.localOnly = const {}});
}

/// Every replicated table, in **dependency order** — parents before children.
///
/// Order matters on apply: `sales_items` referencing an invoice that has not
/// arrived yet would be a live orphan for the length of the batch, and the audit
/// queries would show an invoice with the wrong line count in between. No
/// foreign keys enforce this today (`PRAGMA foreign_keys` is a no-op guard until
/// one is declared), so it is the ordering, not the database, doing the work.
const List<SyncTableSpec> kSyncTables = [
  SyncTableSpec('shop_settings'),
  SyncTableSpec('attribute_definitions'),
  SyncTableSpec('products'),
  SyncTableSpec('product_units'),
  SyncTableSpec('customers'),
  SyncTableSpec('sales_invoices'),
  // The only table whose primary key is NOT its sync identity: `id` is a
  // device-local autoincrement, so two devices mint id=1 for different lines.
  // v16 added `uuid` for exactly this, and the local `id` must never travel —
  // applying a remote row's id would collide with a local line.
  SyncTableSpec('sales_items', syncId: 'uuid', localOnly: {'id'}),
  SyncTableSpec('ledger_entries'),
  SyncTableSpec('cashbox_transactions'),
  SyncTableSpec('stock_movements'),
];

/// Tables whose arrival invalidates a cached `products.quantity`.
///
/// On-hand is derived (`kRecomputeQuantitySql`) but stored, so a batch that
/// brings in someone else's sale must rebuild it — otherwise the movement is in
/// the log and the number on screen still says what it said before the sync,
/// which reads to the shopkeeper as "sync did nothing".
const Set<String> kQuantityAffectingTables = {
  'stock_movements',
  'product_units',
};
