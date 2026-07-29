import 'package:get_it/get_it.dart';

// Core — Database
import 'database/app_database.dart';
import 'database/daos/products_dao.dart';
import 'database/daos/shop_dao.dart';
import 'database/daos/settings_dao.dart';
import 'database/daos/sales_dao.dart';
import 'database/daos/customers_dao.dart';
import 'database/daos/ledger_dao.dart';
import 'database/daos/cashbox_dao.dart';
import 'database/daos/dashboard_dao.dart';
import 'database/daos/attributes_dao.dart';
import 'database/daos/product_units_dao.dart';
import 'database/daos/stock_dao.dart';
import 'database/daos/sync_dao.dart';

// Core — Network
import 'network/api_client.dart';
import 'network/sync_api_client.dart';
import '../features/sync/data/repositories/sync_enrollment_repository_impl.dart';
import '../features/sync/data/sync_credential_store.dart';
import '../features/sync/domain/repositories/sync_enrollment_repository.dart';
import 'config/remote_config_service.dart';
import 'currency/exchange_rate_service.dart';
import 'settings/inventory_settings_service.dart';
import 'settings/print_settings_service.dart';
import 'sync/sync_clock.dart';
import 'theme/font_scale_controller.dart';
import 'theme/theme_controller.dart';

// Features — Attributes (dynamic product fields, Plan 010)
import '../features/attributes/data/repositories/attribute_definition_repository_drift_impl.dart';
import '../features/attributes/domain/repositories/attribute_definition_repository.dart';
import '../features/product/data/repositories/product_unit_repository_drift_impl.dart';
import '../features/product/domain/repositories/product_unit_repository.dart';
import '../features/attributes/presentation/bloc/attribute_definition_bloc.dart';

// Features — Ledger (customers & debts)
import '../features/ledger/data/repositories/customer_repository_drift_impl.dart';
import '../features/ledger/data/repositories/ledger_repository_drift_impl.dart';
import '../features/ledger/domain/repositories/customer_repository.dart';
import '../features/ledger/domain/repositories/ledger_repository.dart';
import '../features/ledger/presentation/bloc/customer_bloc.dart';
import '../features/ledger/presentation/bloc/ledger_bloc.dart';

// Features — Cashbox (cash ledger)
import '../features/cashbox/data/repositories/cashbox_repository_drift_impl.dart';
import '../features/cashbox/domain/repositories/cashbox_repository.dart';
import '../features/cashbox/presentation/bloc/cashbox_bloc.dart';

// Features — Sync (multi-device, Plan 002)
import '../features/sync/data/sync_api_transport.dart';
import '../features/sync/data/sync_engine.dart';
import '../features/sync/data/sync_state_store.dart';
import '../features/sync/domain/sync_transport.dart';

// Features — Backup (cloud backup / restore)
import '../features/backup/data/auto_backup_service.dart';
import '../features/backup/data/backup_engine.dart';
import '../features/backup/data/backup_repository_impl.dart';
import '../features/backup/data/google_drive_backup_target.dart';
import '../features/backup/domain/repositories/backup_repository.dart';
import '../features/backup/presentation/bloc/backup_bloc.dart';

// Features — Licensing (subscription)
import '../features/licensing/data/datasources/license_local_storage.dart';
import '../features/licensing/data/datasources/license_remote_datasource.dart';
import '../features/licensing/data/repositories/license_repository_impl.dart';
import '../features/licensing/data/services/device_identity_service.dart';
import '../features/licensing/data/services/push_notification_service.dart';
import '../features/licensing/domain/repositories/license_repository.dart';
import '../features/licensing/presentation/bloc/license_bloc.dart';

// Features — Product
import '../features/product/data/repositories/product_repository_drift_impl.dart';
import '../features/product/domain/repositories/product_repository.dart';
import '../features/product/presentation/bloc/product_bloc.dart';
import '../features/product/presentation/bloc/product_unit_bloc.dart';

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

// Features — Dashboard (analytics)
import '../features/dashboard/data/repositories/dashboard_repository_drift_impl.dart';
import '../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../features/dashboard/presentation/bloc/dashboard_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Network ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ApiClient>(() => ApiClient());
  sl.registerLazySingleton<RemoteConfigService>(() => RemoteConfigService());

  // ── Database ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // ── DAOs (all share the same AppDatabase instance) ───────────────────────
  sl.registerLazySingleton<ProductsDao>(() => ProductsDao(sl()));
  sl.registerLazySingleton<ShopDao>(() => ShopDao(sl()));
  sl.registerLazySingleton<SettingsDao>(() => SettingsDao(sl()));
  sl.registerLazySingleton<SalesDao>(() => SalesDao(sl()));
  sl.registerLazySingleton<CustomersDao>(() => CustomersDao(sl()));
  sl.registerLazySingleton<LedgerDao>(() => LedgerDao(sl()));
  sl.registerLazySingleton<CashboxDao>(() => CashboxDao(sl()));
  sl.registerLazySingleton<DashboardDao>(() => DashboardDao(sl()));
  sl.registerLazySingleton<AttributesDao>(() => AttributesDao(sl()));
  sl.registerLazySingleton<ProductUnitsDao>(() => ProductUnitsDao(sl()));
  sl.registerLazySingleton<StockDao>(() => StockDao(sl()));
  sl.registerLazySingleton<SyncDao>(() => SyncDao(sl()));

  // ── Sync (Plan 002, Phase 0) ─────────────────────────────────────────────
  // Registered before the repositories because every one that can delete needs
  // it to stamp a tombstone. Its node id is empty until `main()` awaits
  // `load()` — see the startup wiring there.
  sl.registerLazySingleton<SyncClock>(() => SyncClock(sl<SettingsDao>()));

  // Multi-device sync (Plan 002, Phase 1). Registered as singletons because the
  // engine serialises its own passes — two instances would each think they were
  // the only one running and race to advance the cursor.
  // SyncApiClient and SyncCredentialStore are registered with the enrollment
  // block further down; these lazy factories only resolve them on first use,
  // which is after init() has finished, so the order here does not matter.
  sl.registerLazySingleton<SyncStateStore>(
      () => SyncStateStore(sl<SettingsDao>()));
  sl.registerLazySingleton<SyncTransport>(() => SyncApiTransport(
        sl<SyncApiClient>(),
        // Read per request, never captured: the seat token is rotated when a
        // device re-enrolls as owner, and a cached copy would keep sending the
        // dead one until the app restarted.
        () async => (await sl<SyncCredentialStore>().load())?.syncToken,
      ));
  sl.registerLazySingleton<SyncEngine>(() => SyncEngine(
        dao: sl<SyncDao>(),
        transport: sl<SyncTransport>(),
        state: sl<SyncStateStore>(),
        clock: sl<SyncClock>(),
      ));

  // ── Services ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ExchangeRateService>(
      () => ExchangeRateService(sl<SettingsDao>()));
  sl.registerLazySingleton<InventorySettingsService>(
      () => InventorySettingsService(sl<SettingsDao>()));
  sl.registerLazySingleton<PrintSettingsService>(
      () => PrintSettingsService(sl<SettingsDao>()));
  // Singleton, not a factory: `MyApp` listens to this instance and the settings
  // page writes to it — two copies would leave the UI out of sync.
  sl.registerLazySingleton<ThemeController>(
      () => ThemeController(sl<SettingsDao>()));
  sl.registerLazySingleton<FontScaleController>(
      () => FontScaleController(sl<SettingsDao>()));

  // ── Repositories ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<ProductRepository>(
      () => ProductRepositoryDriftImpl(
          sl(), sl<StockDao>(), sl<SyncClock>()));
  sl.registerLazySingleton<ShopRepository>(
      () => ShopRepositoryDriftImpl(sl()));
  sl.registerLazySingleton<PrinterRepository>(
      () => PrinterRepositoryDriftImpl(sl()));
  sl.registerLazySingleton<InvoiceRepository>(
      () => InvoiceRepositoryDriftImpl(sl(), sl<SyncClock>()));
  sl.registerLazySingleton<CustomerRepository>(
      () => CustomerRepositoryDriftImpl(sl(), sl<SyncClock>()));
  sl.registerLazySingleton<LedgerRepository>(
      () => LedgerRepositoryDriftImpl(sl(), sl(), sl(), sl<SyncClock>()));
  sl.registerLazySingleton<CashboxRepository>(
      () => CashboxRepositoryDriftImpl(sl(), sl<SyncClock>()));
  sl.registerLazySingleton<DashboardRepository>(
      () => DashboardRepositoryDriftImpl(sl<DashboardDao>()));
  sl.registerLazySingleton<AttributeDefinitionRepository>(
      () => AttributeDefinitionRepositoryDriftImpl(
          sl<AttributesDao>(), sl<SyncClock>()));
  sl.registerLazySingleton<ProductUnitRepository>(
      () => ProductUnitRepositoryDriftImpl(
          sl<ProductUnitsDao>(), sl<SyncClock>()));

  // ── Backup (Drift snapshot + Google Drive target) ────────────────────────
  sl.registerLazySingleton<BackupEngine>(() => BackupEngine(sl(), sl()));
  sl.registerLazySingleton<GoogleDriveBackupTarget>(
      () => GoogleDriveBackupTarget());
  sl.registerLazySingleton<BackupRepository>(
      () => BackupRepositoryImpl(
          sl<BackupEngine>(),
          sl<GoogleDriveBackupTarget>(),
          sl<SettingsDao>(),
          sl(),
          // Registered further down, but these are lazy singletons: the closure
          // resolves on first access, not here.
          sl<LicenseRepository>()));
  sl.registerLazySingleton<AutoBackupService>(
      () => AutoBackupService(sl<BackupRepository>(), sl<SettingsDao>()));

  // ── Licensing (network-backed; no DAO) ───────────────────────────────────
  sl.registerLazySingleton<DeviceIdentityService>(
      () => const DeviceIdentityService());
  sl.registerLazySingleton<LicenseLocalStorage>(() => LicenseLocalStorage());
  sl.registerLazySingleton<LicenseRemoteDataSource>(
      () => LicenseRemoteDataSource(sl()));
  sl.registerLazySingleton<LicenseRepository>(
      () => LicenseRepositoryImpl(sl(), sl(), sl()));
  sl.registerLazySingleton<PushNotificationService>(
      () => PushNotificationService(sl()));

  // ── Multi-device sync (network-backed; credential in SharedPreferences) ────
  sl.registerLazySingleton<SyncApiClient>(() => SyncApiClient());
  sl.registerLazySingleton<SyncCredentialStore>(() => SyncCredentialStore());
  sl.registerLazySingleton<SyncEnrollmentRepository>(() =>
      SyncEnrollmentRepositoryImpl(
          sl<SyncApiClient>(), sl<SyncCredentialStore>(), sl<DeviceIdentityService>()));

  // ── BLoCs ─────────────────────────────────────────────────────────────────
  sl.registerFactory(
      () => ProductBloc(repository: sl(), printerRepository: sl()));
  sl.registerFactory(
      () => AttributeDefinitionBloc(repository: sl<AttributeDefinitionRepository>()));

  sl.registerFactory(() => ShopBloc(repository: sl()));

  sl.registerFactory(() => PrinterBloc(repository: sl()));

  // Route-scoped to /products/units/:id (one SKU's handsets at a time).
  sl.registerFactory(() => ProductUnitBloc(repository: sl()));

  sl.registerFactory(
      () => HistoryBloc(repository: sl(), printerRepository: sl()));

  sl.registerFactory(() => BillingBloc(
        productRepository: sl(),
        printerRepository: sl(),
        invoiceRepository: sl(),
        exchangeRateService: sl(),
        inventorySettingsService: sl(),
        printSettingsService: sl(),
        attributeRepository: sl(),
        productUnitRepository: sl(),
      ));

  sl.registerFactory(() => CustomerBloc(repository: sl()));
  sl.registerFactory(() => LedgerBloc(
        customerRepository: sl(),
        ledgerRepository: sl(),
        printerRepository: sl(),
      ));

  sl.registerFactory(() => CashboxBloc(repository: sl()));

  sl.registerFactory(() => DashboardBloc(repository: sl()));

  sl.registerFactory(() => BackupBloc(repository: sl<BackupRepository>(), autoBackup: sl<AutoBackupService>()));

  // LicenseBloc is a SINGLETON (not a factory): the GoRouter gate redirect and
  // the widget tree must observe the same instance for the gate to react.
  sl.registerLazySingleton<LicenseBloc>(() => LicenseBloc(repository: sl()));
}
