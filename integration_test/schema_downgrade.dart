// Turns the CURRENT schema back into an older one, so a migration test can
// stamp the old `user_version` and let the real `onUpgrade` run against it.
//
// WHY THIS IS SHARED, and why it must strip DOWNWARDS from the current version:
// each migration test used to build its fixture by opening the current schema
// and dropping only its OWN version's additions. That works exactly until the
// next migration lands — the fixture then carries columns from a LATER version
// while claiming an older `user_version`, so `onUpgrade` tries to add them a
// second time and dies with "duplicate column name". Both the v14 and v15 tests
// broke this way the moment v16 shipped, and the failure reads like a migration
// bug when it is really a lying fixture.
//
// So: a test targeting vN calls every strip from the current version down to
// N+1, in descending order. Adding a migration means adding one function here
// and one call line in each older test.
import 'package:billing_app/core/database/app_database.dart';

/// Tables that gained sync metadata in v16.
const kSyncedTables = [
  'products',
  'customers',
  'shop_settings',
  'sales_invoices',
  'sales_items',
  'ledger_entries',
  'cashbox_transactions',
  'product_units',
  'attribute_definitions',
];

/// Undo v16 (Plan 002 Phase 0 — sync metadata, `sales_items.uuid`,
/// `products.created_at`).
Future<void> stripV16(AppDatabase db) async {
  // Indexes first: SQLite refuses DROP COLUMN on a column any index references.
  for (final t in kSyncedTables) {
    await db.customStatement('DROP INDEX IF EXISTS idx_${t}_updated_at');
  }
  await db.customStatement('DROP INDEX IF EXISTS idx_sales_items_uuid');

  for (final t in kSyncedTables) {
    await db.customStatement('ALTER TABLE $t DROP COLUMN updated_at');
    await db.customStatement('ALTER TABLE $t DROP COLUMN deleted_at');
    await db.customStatement('ALTER TABLE $t DROP COLUMN origin_device');
  }
  await db.customStatement('ALTER TABLE sales_items DROP COLUMN uuid');
  await db.customStatement('ALTER TABLE products DROP COLUMN created_at');
}

/// Undo v15 (Plan 012 — serialized units). Dropping `product_units` takes its
/// indexes with it, so they need no separate statement.
Future<void> stripV15(AppDatabase db) async {
  await db.customStatement('DROP TABLE IF EXISTS product_units');
  await db.customStatement('ALTER TABLE products DROP COLUMN is_serialized');
  await db.customStatement('ALTER TABLE sales_items DROP COLUMN serial_snapshot');
}

/// Undo v14 (Plan 011 #10 — the `sales_items.sale_type` snapshot).
Future<void> stripV14(AppDatabase db) async {
  await db.customStatement('ALTER TABLE sales_items DROP COLUMN sale_type');
}
