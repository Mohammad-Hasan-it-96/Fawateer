import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/products_table.dart';
import 'tables/shop_settings_table.dart';
import 'tables/app_settings_table.dart';
import 'tables/sales_invoices_table.dart';
import 'tables/sales_items_table.dart';
import 'tables/purchase_invoices_table.dart';
import 'tables/purchase_items_table.dart';
import 'tables/customers_table.dart';
import 'tables/debts_table.dart';
import 'tables/cashbox_entries_table.dart';

import 'daos/products_dao.dart';
import 'daos/shop_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/sales_dao.dart';
import 'daos/purchases_dao.dart';
import 'daos/customers_dao.dart';
import 'daos/debts_dao.dart';
import 'daos/cashbox_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Products,
    ShopSettings,
    AppSettings,
    SalesInvoices,
    SalesItems,
    PurchaseInvoices,
    PurchaseItems,
    Customers,
    Debts,
    CashboxEntries,
  ],
  daos: [
    ProductsDao,
    ShopDao,
    SettingsDao,
    SalesDao,
    PurchasesDao,
    CustomersDao,
    DebtsDao,
    CashboxDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'fawateer'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(shopSettings, shopSettings.currencySymbol);
      }
    },
  );
}

