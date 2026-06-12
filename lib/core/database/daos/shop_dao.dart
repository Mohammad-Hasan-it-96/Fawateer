import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/shop_settings_table.dart';

part 'shop_dao.g.dart';

@DriftAccessor(tables: [ShopSettings])
class ShopDao extends DatabaseAccessor<AppDatabase> with _$ShopDaoMixin {
  ShopDao(super.db);

  static const String _defaultId = 'default';

  /// Returns the single shop row, or null if the DB is empty.
  Future<ShopRow?> getShop() =>
      (select(shopSettings)..where((s) => s.id.equals(_defaultId)))
          .getSingleOrNull();

  /// Insert or replace the shop row (upsert).
  Future<void> upsertShop(ShopSettingsCompanion row) =>
      into(shopSettings).insertOnConflictUpdate(row);
}

