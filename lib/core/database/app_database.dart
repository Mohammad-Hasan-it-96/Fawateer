import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/products_table.dart';
import 'tables/shop_settings_table.dart';
import 'tables/app_settings_table.dart';
import 'tables/sales_invoices_table.dart';
import 'tables/sales_items_table.dart';
import 'tables/customers_table.dart';
import 'tables/ledger_entries_table.dart';

import 'daos/products_dao.dart';
import 'daos/shop_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/sales_dao.dart';
import 'daos/customers_dao.dart';
import 'daos/ledger_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Products,
    ShopSettings,
    AppSettings,
    SalesInvoices,
    SalesItems,
    Customers,
    LedgerEntries,
  ],
  daos: [
    ProductsDao,
    ShopDao,
    SettingsDao,
    SalesDao,
    CustomersDao,
    LedgerDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'fawateer'));

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createIndexes();
      await _createLedgerIndexes();
    },
    beforeOpen: (details) async {
      // Enforce foreign keys for every connection. Set here (after migrations
      // run) — not inside onUpgrade, where table rebuilds need FKs off. No FK
      // constraints are declared yet, so this is currently a no-op guard that
      // makes any FK added by a future feature actually enforced.
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(shopSettings, shopSettings.currencySymbol);
      }
      if (from < 3) {
        // Drop tables for removed features (customers, purchases, cashbox).
        for (final table in const [
          'customers',
          'debts',
          'purchase_invoices',
          'purchase_items',
          'cashbox_entries',
        ]) {
          await customStatement('DROP TABLE IF EXISTS $table');
        }
      }
      if (from < 4) {
        // Add cost columns (selling cost for margin/profit) and POS indexes.
        await migrator.addColumn(products, products.cost);
        await migrator.addColumn(salesItems, salesItems.cost);
        await _createIndexes();
      }
      if (from < 5) {
        // Inventory: int `stock` -> double `quantity` (+ low-stock threshold).
        // Existing counts are copied over; no data loss. The old `stock` column
        // is left orphaned (has DEFAULT 0, so inserts that omit it still work),
        // matching how `upiId` removal was handled — avoids a table rebuild.
        await migrator.addColumn(products, products.quantity);
        await migrator.addColumn(products, products.minStockAlert);
        await customStatement('UPDATE products SET quantity = stock');
      }
      if (from < 6) {
        // sales_items.quantity int -> double (matches products.quantity, so a
        // weight/fractional sale can be recorded). SQLite can't change a column
        // type in place, so rebuild the table; existing integer quantities copy
        // over as reals. The rebuild drops the table's indexes, so recreate them.
        await migrator.alterTable(TableMigration(salesItems));
        await _createIndexes();
      }
      if (from < 7) {
        // Customer debt ledger: new customers + ledger_entries tables. Additive
        // — no existing table is touched (the sale↔customer link lives on the
        // ledger entry's invoiceId, so sales_invoices needs no change).
        await migrator.createTable(customers);
        await migrator.createTable(ledgerEntries);
        await _createLedgerIndexes();
      }
      if (from < 8) {
        // Sale type (piece vs weight/…): additive text column, defaults 'piece'
        // so every existing product keeps its current per-piece behavior.
        await migrator.addColumn(products, products.saleType);
      }
    },
  );

  /// Idempotent index creation (`IF NOT EXISTS`), shared by [onCreate] and the
  /// v3→v4 / v5→v6 upgrades (the latter rebuilds sales_items, dropping its
  /// indexes). Names use Drift's snake_case for tables/columns.
  Future<void> _createIndexes() async {
    // A legacy v1–v3 DB had no unique barcode index, so a shop could hold two
    // products sharing a non-empty barcode. Creating the partial-unique index
    // over such data throws mid-migration and bricks the DB on every launch, so
    // de-dup FIRST: keep the earliest row per barcode, blank the rest (the
    // product stays; only its now-ambiguous barcode is cleared). No-op on a
    // fresh/clean DB.
    await customStatement(
        "UPDATE products SET barcode = '' "
        "WHERE barcode != '' AND rowid NOT IN ("
        "SELECT MIN(rowid) FROM products WHERE barcode != '' GROUP BY barcode)");
    await customStatement(
        "CREATE UNIQUE INDEX IF NOT EXISTS idx_products_barcode ON products (barcode) WHERE barcode != ''");
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sales_invoices_created_at ON sales_invoices (created_at)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sales_items_invoice_id ON sales_items (invoice_id)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sales_items_product_id ON sales_items (product_id)');
  }

  /// Idempotent indexes for the debt-ledger tables. Called from [onCreate] and
  /// the v6→v7 upgrade. Speeds up per-customer entry lookups and the
  /// invoice→ledger join used to tell whether a sale was on credit.
  Future<void> _createLedgerIndexes() async {
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_ledger_customer_id ON ledger_entries (customer_id)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_ledger_invoice_id ON ledger_entries (invoice_id)');
  }
}

