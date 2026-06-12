import 'package:get_it/get_it.dart';

// Core — Database
import 'database/app_database.dart';
import 'database/daos/products_dao.dart';
import 'database/daos/shop_dao.dart';
import 'database/daos/settings_dao.dart';
import 'database/daos/sales_dao.dart';
import 'database/daos/purchases_dao.dart';
import 'database/daos/customers_dao.dart';
import 'database/daos/debts_dao.dart';
import 'database/daos/cashbox_dao.dart';

// Features — Product
import '../features/product/data/repositories/product_repository_drift_impl.dart';
import '../features/product/domain/repositories/product_repository.dart';
import '../features/product/domain/usecases/product_usecases.dart';
import '../features/product/presentation/bloc/product_bloc.dart';

// Features — Shop
import '../features/shop/data/repositories/shop_repository_drift_impl.dart';
import '../features/shop/domain/repositories/shop_repository.dart';
import '../features/shop/domain/usecases/shop_usecases.dart';
import '../features/shop/presentation/bloc/shop_bloc.dart';

// Features — Settings / Printer
import '../features/settings/data/repositories/printer_repository_drift_impl.dart';
import '../features/settings/domain/repositories/printer_repository.dart';
import '../features/settings/presentation/bloc/printer_bloc.dart';

// Features — Billing (invoices)
import '../features/billing/data/repositories/invoice_repository_drift_impl.dart';
import '../features/billing/domain/repositories/invoice_repository.dart';
import '../features/billing/domain/usecases/invoice_usecases.dart';
import '../features/billing/presentation/bloc/billing_bloc.dart';
import '../features/billing/presentation/bloc/history_bloc.dart';

// Features — Customers & Debts
import '../features/customers/data/repositories/customer_repository_drift_impl.dart';
import '../features/customers/domain/repositories/customer_repository.dart';

// Features — Purchases
import '../features/purchases/data/repositories/purchase_repository_drift_impl.dart';
import '../features/purchases/domain/repositories/purchase_repository.dart';

// Features — Cashbox
import '../features/cashbox/data/repositories/cashbox_repository_drift_impl.dart';
import '../features/cashbox/domain/repositories/cashbox_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Database ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // ── DAOs (all share the same AppDatabase instance) ───────────────────────
  sl.registerLazySingleton<ProductsDao>(() => ProductsDao(sl()));
  sl.registerLazySingleton<ShopDao>(() => ShopDao(sl()));
  sl.registerLazySingleton<SettingsDao>(() => SettingsDao(sl()));
  sl.registerLazySingleton<SalesDao>(() => SalesDao(sl()));
  sl.registerLazySingleton<PurchasesDao>(() => PurchasesDao(sl()));
  sl.registerLazySingleton<CustomersDao>(() => CustomersDao(sl()));
  sl.registerLazySingleton<DebtsDao>(() => DebtsDao(sl()));
  sl.registerLazySingleton<CashboxDao>(() => CashboxDao(sl()));

  // ── Repositories ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<ProductRepository>(
      () => ProductRepositoryDriftImpl(sl()));
  sl.registerLazySingleton<ShopRepository>(
      () => ShopRepositoryDriftImpl(sl()));
  sl.registerLazySingleton<PrinterRepository>(
      () => PrinterRepositoryDriftImpl(sl()));
  sl.registerLazySingleton<InvoiceRepository>(
      () => InvoiceRepositoryDriftImpl(sl()));
  sl.registerLazySingleton<CustomerRepository>(
      () => CustomerRepositoryDriftImpl(sl(), sl()));
  sl.registerLazySingleton<PurchaseRepository>(
      () => PurchaseRepositoryDriftImpl(sl()));
  sl.registerLazySingleton<CashboxRepository>(
      () => CashboxRepositoryDriftImpl(sl()));

  // ── Use Cases ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => AddProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
  sl.registerLazySingleton(() => DeleteProductUseCase(sl()));
  sl.registerLazySingleton(() => GetProductByBarcodeUseCase(sl()));

  sl.registerLazySingleton(() => GetShopUseCase(sl()));
  sl.registerLazySingleton(() => UpdateShopUseCase(sl()));

  sl.registerLazySingleton(() => GetAllInvoicesUseCase(sl()));
  sl.registerLazySingleton(() => GetInvoiceItemsUseCase(sl()));

  // ── BLoCs ─────────────────────────────────────────────────────────────────
  sl.registerFactory(() => ProductBloc(
        getProductsUseCase: sl(),
        addProductUseCase: sl(),
        updateProductUseCase: sl(),
        deleteProductUseCase: sl(),
      ));

  sl.registerFactory(() => ShopBloc(
        getShopUseCase: sl(),
        updateShopUseCase: sl(),
      ));

  sl.registerFactory(() => PrinterBloc(repository: sl()));

  sl.registerFactory(() => HistoryBloc(
        getAllInvoicesUseCase: sl(),
        getInvoiceItemsUseCase: sl(),
      ));

  sl.registerFactory(() => BillingBloc(
        getProductByBarcodeUseCase: sl(),
        printerRepository: sl(),
        invoiceRepository: sl(),
        updateProductUseCase: sl(),
      ));
}
