import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/products_table.dart';
import 'tables/shop_settings_table.dart';
import 'tables/app_settings_table.dart';
import 'tables/sales_invoices_table.dart';
import 'tables/sales_items_table.dart';
import 'tables/customers_table.dart';
import 'tables/ledger_entries_table.dart';
import 'tables/cashbox_transactions_table.dart';
import 'tables/attribute_definitions_table.dart';
import 'tables/product_units_table.dart';
import 'sync_tables.dart';
import 'tables/stock_movements_table.dart';

import 'daos/products_dao.dart';
import 'daos/shop_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/sales_dao.dart';
import 'daos/customers_dao.dart';
import 'daos/ledger_dao.dart';
import 'daos/cashbox_dao.dart';
import 'daos/dashboard_dao.dart';
import 'daos/attributes_dao.dart';
import 'daos/product_units_dao.dart';
import 'daos/stock_dao.dart';
import 'daos/sync_dao.dart';

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
    CashboxTransactions,
    AttributeDefinitions,
    ProductUnits,
    StockMovements,
  ],
  daos: [
    ProductsDao,
    ShopDao,
    SettingsDao,
    SalesDao,
    CustomersDao,
    LedgerDao,
    CashboxDao,
    DashboardDao,
    AttributesDao,
    ProductUnitsDao,
    StockDao,
    SyncDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'fawateer'));

  /// Test-only: build the database over a caller-supplied executor (e.g. an
  /// in-memory `NativeDatabase.memory()`), so integration tests can exercise the
  /// real schema/migrations/SQL against the device's bundled SQLite without
  /// touching the app's on-disk `fawateer` database.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 19;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createIndexes();
      await _createLedgerIndexes();
      await _createCashboxIndexes();
      await _createProductUnitIndexes();
      await _createStockIndexes();
      await _createSyncIndexes();
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
        //
        // The rebuild emits the CURRENT sales_items definition, so on a v1–v5
        // install this table arrives already carrying every later addition — which
        // is why every subsequent addColumn goes through _addColumnIfMissing.
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
      if (from < 9) {
        // Cashbox: new signed-entry cash ledger. Additive — no existing table is
        // touched. (A same-named `cashbox_entries` from a removed pre-v3 feature
        // was already dropped in the v2→v3 step; this uses a distinct name.)
        await migrator.createTable(cashboxTransactions);
        await _createCashboxIndexes();
      }
      if (from < 10) {
        // Dual currency (SP base + USD sticker): additive text/real columns,
        // all with defaults so existing rows decode as SP-native. products
        // gains the price currency; sales_items gains the per-line FX snapshot
        // (currency/rate/original) used for display & audit. No table rebuild.
        await _addColumnIfMissing(
            migrator, products, products.priceCurrency);
        await _addColumnIfMissing(
            migrator, salesItems, salesItems.priceCurrency);
        await _addColumnIfMissing(migrator, salesItems, salesItems.fxRate);
        await _addColumnIfMissing(
            migrator, salesItems, salesItems.priceOriginal);
      }
      if (from < 11) {
        // The old '₹' (Indian rupee) default was wrong for this Syria-first app.
        // Normalize it — and any blank symbol — to the Syrian pound. A shop that
        // deliberately chose another symbol keeps it.
        await customStatement(
            "UPDATE shop_settings SET currency_symbol = 'ل.س' "
            "WHERE currency_symbol = '₹' OR currency_symbol = ''");
      }
      if (from < 12) {
        // Manual discounts (Plan 005): additive SP-discount columns. Every
        // existing row decodes as "no discount". No table rebuild.
        await _addColumnIfMissing(migrator, salesItems, salesItems.discount);
        await _addColumnIfMissing(
            migrator, salesInvoices, salesInvoices.invoiceDiscount);
      }
      if (from < 13) {
        // Dynamic product attributes (Plan 010, bucket A). Purely additive:
        //  - products.attributes: JSON bag of custom field values ('' = none)
        //  - sales_items.attributes_snapshot: printed attributes frozen at sale
        //  - attribute_definitions: the owner's custom-field metadata (new table)
        // No existing table is touched; every existing row decodes as empty.
        await _addColumnIfMissing(migrator, products, products.attributes);
        await _addColumnIfMissing(
            migrator, salesItems, salesItems.attributesSnapshot);
        await migrator.createTable(attributeDefinitions);
      }
      if (from < 14) {
        // Unit fidelity (Plan 011 #10): snapshot how the line was sold, so a
        // reprint keeps its "كغ" and the invoice table stops guessing kg-vs-
        // piece from the quantity. Additive; existing rows decode as ''
        // (unknown) and keep using the old heuristic.
        await _addColumnIfMissing(migrator, salesItems, salesItems.saleType);
      }
      if (from < 15) {
        // Serialized units (Plan 012, bucket C of Plan 010): per-physical-item
        // identity, so a phone shop holding five identical handsets holds one
        // product row and five unit rows — and can answer "which invoice sold
        // THIS IMEI, and is it still under warranty?".
        //
        // Purely additive (addColumn ×2 + createTable): every existing product
        // decodes as non-serialized and every existing sale line as having no
        // serial, so nothing changes for a shop that never opts in.
        await _addColumnIfMissing(migrator, products, products.isSerialized);
        await _addColumnIfMissing(
            migrator, salesItems, salesItems.serialSnapshot);
        await migrator.createTable(productUnits);
        await _createProductUnitIndexes();
      }
      if (from < 16) {
        // Multi-device sync groundwork (Plan 002, Phase 0). No sync code runs
        // yet — this only gives every replicated row somewhere to record *when*
        // it changed, *whether* it was deleted, and *which device* changed it.
        //
        // Doing it before any device syncs is deliberate: these columns must
        // exist on a shop's database before that shop's data can ever be split
        // across two devices, and the migration gets more expensive with every
        // install. Purely additive — every existing row decodes as "predates
        // sync, not deleted, origin unknown", which is exactly true.
        // Columns are passed as typed references rather than looked up by name.
        // A mistyped string here would throw *during* a shop's upgrade — the
        // one failure this file works hardest to avoid (see the barcode de-dup
        // in _createIndexes) — and no test would catch it on a fresh database.
        // This way it is a compile error.
        Future<void> addSyncMeta(
          TableInfo table,
          GeneratedColumn updated,
          GeneratedColumn deleted,
          GeneratedColumn origin,
        ) async {
          await _addColumnIfMissing(migrator, table, updated);
          await _addColumnIfMissing(migrator, table, deleted);
          await _addColumnIfMissing(migrator, table, origin);
        }

        await addSyncMeta(products, products.updatedAt, products.deletedAt,
            products.originDevice);
        await addSyncMeta(customers, customers.updatedAt, customers.deletedAt,
            customers.originDevice);
        await addSyncMeta(shopSettings, shopSettings.updatedAt,
            shopSettings.deletedAt, shopSettings.originDevice);
        await addSyncMeta(salesInvoices, salesInvoices.updatedAt,
            salesInvoices.deletedAt, salesInvoices.originDevice);
        await addSyncMeta(salesItems, salesItems.updatedAt,
            salesItems.deletedAt, salesItems.originDevice);
        await addSyncMeta(ledgerEntries, ledgerEntries.updatedAt,
            ledgerEntries.deletedAt, ledgerEntries.originDevice);
        await addSyncMeta(cashboxTransactions, cashboxTransactions.updatedAt,
            cashboxTransactions.deletedAt, cashboxTransactions.originDevice);
        await addSyncMeta(productUnits, productUnits.updatedAt,
            productUnits.deletedAt, productUnits.originDevice);
        await addSyncMeta(
            attributeDefinitions,
            attributeDefinitions.updatedAt,
            attributeDefinitions.deletedAt,
            attributeDefinitions.originDevice);

        // Sync identity for sale lines. The table's own `id` is an
        // autoincrement int — device-local, so two devices mint id=1 for
        // different lines. Backfilled deterministically rather than with random
        // UUIDs: `invoice_id` is already globally unique, so `invoice_id-id` is
        // too, it needs no Dart round-trip over every historical row, and
        // re-running this step would produce identical values.
        await _addColumnIfMissing(migrator, salesItems, salesItems.uuid);
        await customStatement(
            "UPDATE sales_items SET uuid = invoice_id || '-' || id "
            "WHERE uuid = ''");

        // Newest-first ordering (Plan 011 #5) used `rowId desc`, which is local
        // insertion order and disagrees between devices. Existing rows keep 0
        // so they sort oldest rather than claiming a creation time we do not
        // know; only genuinely new products carry a real one.
        await _addColumnIfMissing(migrator, products, products.createdAt);

        await _createSyncIndexes();
      }
      if (from < 17) {
        // Tombstones (Plan 002, Phase 0). No new columns — `deleted_at` already
        // arrived in v16. What changes is the two partial-UNIQUE indexes, which
        // must stop counting deleted rows.
        //
        // Without this, deleting is a one-way door: a shop that deletes a
        // product can never re-add anything with that barcode, and a shop that
        // deletes a unit can never re-enter that serial, because the tombstoned
        // row still occupies the value. Hard deletes hid the problem; soft
        // deletes surface it immediately.
        //
        // Recreated rather than adjusted — SQLite has no ALTER INDEX. Dropping
        // a unique index momentarily is safe here: nothing else writes during a
        // migration.
        await customStatement('DROP INDEX IF EXISTS idx_products_barcode');
        await customStatement('DROP INDEX IF EXISTS idx_product_units_serial');
        await _createIndexes();
        await _createProductUnitIndexes();
      }
      if (from < 18) {
        // Stock movement log (Plan 002, Phase 0 — "inventory, the hard one").
        // `products.quantity` stops being the truth and becomes a cache of
        // SUM(delta): a scalar merged last-write-wins loses sales outright
        // (two devices each selling one of five converge on "4"), whereas
        // append-only movements merge by union and both sales count.
        await migrator.createTable(stockMovements);
        await _createStockIndexes();
        await _createSyncIndexes();

        // Backfill: every product with stock gets one opening-balance movement
        // so the log already sums to what the shop currently sees. Without it
        // the first recompute would wipe every on-hand count to zero — the
        // migration would look like it deleted the shop's entire inventory.
        //
        // Deterministic ids ('opening-<product id>'), never random: this must be
        // safe to re-run, and two devices that both migrate before their first
        // sync must produce the *same* row rather than two opening balances
        // that sum to double the real stock.
        //
        // Serialized SKUs are skipped — their `product_units` rows already ARE
        // an append-only, uuid-keyed, merge-safe log, so a second ledger could
        // only disagree with them (see kRecomputeQuantitySql).
        //
        // `updated_at` is left '' ("predates sync") deliberately: these are
        // reconstructed history, not edits this device authored, and claiming
        // a real stamp would let them beat genuine remote edits.
        await customStatement(
            "INSERT INTO stock_movements "
            '(id, product_id, delta, reason, related_id, note, '
            ' occurred_at, created_at) '
            "SELECT 'opening-' || id, id, quantity, 'openingBalance', '', '', "
            '       0, 0 '
            'FROM products '
            "WHERE deleted_at = '' AND is_serialized = 0 AND quantity != 0");
      }
      if (from < 19) {
        // Shared barcodes (Plan 015 Case A). One packet, two prices, two piles
        // on the shelf — so `idx_products_barcode` stops being UNIQUE.
        //
        // **Index only. No column, no table, no data touched.** Nothing about
        // an existing shop changes on upgrade: every product keeps its barcode
        // and its stock, and a shop that never adds a second price never sees
        // a difference. The only thing that becomes possible is a second
        // product deliberately created against the same code.
        //
        // Dropped and recreated because SQLite has no ALTER INDEX, and because
        // `CREATE INDEX IF NOT EXISTS` would silently leave the *unique* one in
        // place — the upgrade would appear to work and the feature would refuse
        // every variant with a constraint error.
        await customStatement('DROP INDEX IF EXISTS idx_products_barcode');
        await _createIndexes();
      }
    },
  );

  /// `migrator.addColumn`, but a no-op when the column is already there.
  ///
  /// Load-bearing for any step whose columns can arrive by a second route.
  /// `migrator.createTable`/`alterTable` always emit the **current** Dart table
  /// definition — not the definition as of the version being migrated to — so an
  /// upgrade that runs an earlier table-creating step first already has the later
  /// columns by the time the later step runs. Concretely for v16: an install
  /// below v15 creates `customers`/`ledger_entries` (v7), `cashbox_transactions`
  /// (v9), `attribute_definitions` (v13) and `product_units` (v15) on the way
  /// past, and v6 rebuilds `sales_items` — all five arriving with the v16 sync
  /// columns already attached. Adding them again throws `duplicate column name`
  /// and the shop's database fails to open.
  ///
  /// Caught on a device by migration_v14_test/migration_v15_test: without this,
  /// every install older than v15 bricks on upgrade. Checking the live schema
  /// beats branching on `from`, because it stays correct when a future step adds
  /// another table to that set.
  ///
  /// Routing *shipped* steps through this is the one sanctioned exception to
  /// "never edit a shipped block": it cannot change the outcome of an upgrade
  /// that already succeeded (the column was absent, so it is still added) and
  /// only rescues the paths that previously threw.
  Future<void> _addColumnIfMissing(
      Migrator migrator, TableInfo table, GeneratedColumn column) async {
    final info =
        await customSelect('PRAGMA table_info(${table.actualTableName})').get();
    final present = info.any((row) => row.read<String>('name') == column.name);
    if (!present) await migrator.addColumn(table, column);
  }

  /// Idempotent indexes supporting sync (Plan 002, Phase 0). Called from
  /// [onCreate] and from every upgrade step that adds a replicated table.
  ///
  /// **Tables that do not exist yet are skipped, deliberately.** This helper is
  /// called from the *v16* step, but the list it walks grows every time a new
  /// synced table ships — `stock_movements` arrived in v18. An upgrade starting
  /// below 16 runs the v16 step first, when that table is still several steps
  /// away, and `CREATE INDEX` on a missing table throws and bricks the upgrade.
  /// Caught on a device by `migration_v16_test`; it is the same shape as the
  /// trap `_addColumnIfMissing` exists for, and skipping is the fix that keeps
  /// working when the next synced table lands: the step that creates the table
  /// calls this again immediately afterwards, so nothing is left unindexed.
  Future<void> _createSyncIndexes() async {
    final existing = (await customSelect(
                "SELECT name FROM sqlite_master WHERE type = 'table'")
            .get())
        .map((row) => row.read<String>('name'))
        .toSet();

    // The push path asks each table "what changed since my last cursor" —
    // an `updated_at` scan per table. Cheap to index, and these are the queries
    // that run on every sync tick.
    //
    // Driven off [kSyncTables] rather than a list of its own: a table that
    // replicates but is not indexed here would still work, just with a full
    // scan per sync tick on a table that only ever grows — the kind of thing
    // nobody notices until a shop with two years of sales says sync got slow.
    for (final spec in kSyncTables) {
      final table = spec.table;
      if (!existing.contains(table)) continue;
      await customStatement('CREATE INDEX IF NOT EXISTS '
          'idx_${table}_updated_at ON $table (updated_at)');
    }
    // Sale lines arriving from another device are matched by this, so it is a
    // uniqueness constraint as much as a lookup. Partial over non-empty values,
    // mirroring idx_products_barcode: a row that predates the backfill must
    // stay legal rather than brick the migration.
    if (existing.contains('sales_items')) {
      await customStatement('CREATE UNIQUE INDEX IF NOT EXISTS '
          "idx_sales_items_uuid ON sales_items (uuid) WHERE uuid != ''");
    }
  }

  /// Idempotent index creation (`IF NOT EXISTS`), shared by [onCreate] and the
  /// v3→v4 / v5→v6 upgrades (the latter rebuilds sales_items, dropping its
  /// indexes). Names use Drift's snake_case for tables/columns.
  Future<void> _createIndexes() async {
    // **Not unique any more** (v19, Plan 015 Case A). The shop sells the same
    // packet of cigarettes at two prices from two piles on the shelf, and the
    // factory gave both the same code — so one barcode legitimately resolves to
    // two products, each with its own stock, cost and sales history.
    //
    // The de-dup that used to run here is gone with it. It blanked the barcode
    // on all but the earliest row per code, because creating a UNIQUE index
    // over a legacy v1–v3 database holding duplicates throws mid-migration and
    // bricks the DB on every launch. With a plain index nothing can throw, and
    // keeping that statement would now destroy exactly the data this feature
    // exists to hold.
    //
    // **The guard moved rather than disappearing.** A mistyped duplicate is
    // still a common mistake and is still refused — by the add/edit form,
    // unless the user came through "add another price for this product". See
    // `productBarcodeTaken` and `AddProductPage.variantOf`. Uniqueness is now a
    // property of the flow that creates products, not of the table.
    //
    // Still scoped to LIVE rows (v17): a tombstoned product keeps its barcode
    // because the row is history and must stay readable.
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_products_barcode '
        "ON products (barcode) WHERE barcode != '' AND deleted_at = ''");
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

  /// Idempotent indexes for the cashbox table. Called from [onCreate] and the
  /// v8→v9 upgrade. Speeds up the date-ordered history and the source→entry
  /// lookup used to reverse a cashbox entry when its invoice/ledger row is
  /// deleted.
  Future<void> _createCashboxIndexes() async {
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_cashbox_occurred_at ON cashbox_transactions (occurred_at)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_cashbox_related_id ON cashbox_transactions (related_id)');
  }

  /// Idempotent indexes for the stock movement log (Plan 002, Phase 0), called
  /// from [onCreate] and the v17→v18 upgrade.
  ///
  /// Both queries this backs run on every stock write: on-hand is
  /// `SUM(delta) WHERE product_id = ?`, and deleting an invoice reverses its
  /// movements by `related_id` — the same pair `_createCashboxIndexes` exists
  /// for, because it is the same shape of ledger.
  Future<void> _createStockIndexes() async {
    await customStatement('CREATE INDEX IF NOT EXISTS '
        'idx_stock_movements_product_id ON stock_movements (product_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS '
        'idx_stock_movements_related_id ON stock_movements (related_id)');
  }

  /// Idempotent indexes for serialized units (Plan 012), called from [onCreate]
  /// and the v14→v15 upgrade.
  ///
  /// The serial index is **partial-unique over non-empty values**, mirroring
  /// `idx_products_barcode`: an IMEI identifies one handset on earth, so the
  /// shop must not be able to enter it twice and sell one phone twice — but a
  /// blank serial (a unit logged before its label was read) stays allowed.
  ///
  /// No de-dup pass is needed here, unlike `_createIndexes()`: this table is
  /// created by the very migration that adds the index, so it cannot already
  /// hold conflicting rows.
  Future<void> _createProductUnitIndexes() async {
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_product_units_product_id ON product_units (product_id)');
    // Live rows only (v17), for the same reason as idx_products_barcode: a
    // tombstoned unit keeps its serial as the warranty record, but a returned
    // handset re-entered later must not be refused as a duplicate.
    await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_product_units_serial '
        "ON product_units (serial) WHERE serial != '' AND deleted_at = ''");
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_product_units_invoice ON product_units (sold_invoice_id)');
  }
}

