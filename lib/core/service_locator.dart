import 'package:get_it/get_it.dart';

// Core — Database
import 'database/app_database.dart';
import 'database/daos/products_dao.dart';
import 'database/daos/shop_dao.dart';
import 'database/daos/settings_dao.dart';
import 'database/daos/sales_dao.dart';

// Features — Product
import '../features/product/data/repositories/product_repository_drift_impl.dart';
import '../features/product/domain/repositories/product_repository.dart';
import '../features/product/presentation/bloc/product_bloc.dart';

// Features — Shop
import '../features/shop/data/repositories/shop_repository_drift_impl.dart';
import '../features/shop/domain/repositories/shop_repository.dart';
import '../features/shop/presentation/bloc/shop_bloc.dart';

// Features — Settings / Printer
import '../features/settings/data/repositories/printer_repository_drift_impl.dart';
import '../features/settings/domain/repositories/printer_repository.dart';
import '../features/settings/presentation/bloc/printer_bloc.dart';

// Features — Billing (invoices)
import '../features/billing/data/repositories/invoice_repository_drift_impl.dart';
import '../features/billing/domain/repositories/invoice_repository.dart';
import '../features/billing/presentation/bloc/billing_bloc.dart';
import '../features/billing/presentation/bloc/history_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Database ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // ── DAOs (all share the same AppDatabase instance) ───────────────────────
  sl.registerLazySingleton<ProductsDao>(() => ProductsDao(sl()));
  sl.registerLazySingleton<ShopDao>(() => ShopDao(sl()));
  sl.registerLazySingleton<SettingsDao>(() => SettingsDao(sl()));
  sl.registerLazySingleton<SalesDao>(() => SalesDao(sl()));

  // ── Repositories ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<ProductRepository>(
      () => ProductRepositoryDriftImpl(sl()));
  sl.registerLazySingleton<ShopRepository>(
      () => ShopRepositoryDriftImpl(sl()));
  sl.registerLazySingleton<PrinterRepository>(
      () => PrinterRepositoryDriftImpl(sl()));
  sl.registerLazySingleton<InvoiceRepository>(
      () => InvoiceRepositoryDriftImpl(sl()));

  // ── BLoCs ─────────────────────────────────────────────────────────────────
  sl.registerFactory(() => ProductBloc(repository: sl()));

  sl.registerFactory(() => ShopBloc(repository: sl()));

  sl.registerFactory(() => PrinterBloc(repository: sl()));

  sl.registerFactory(() => HistoryBloc(repository: sl()));

  sl.registerFactory(() => BillingBloc(
        productRepository: sl(),
        printerRepository: sl(),
        invoiceRepository: sl(),
      ));
}
