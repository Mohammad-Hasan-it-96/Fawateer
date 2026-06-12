import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/app_settings_table.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// Retrieve a setting value by [key], or null if not set.
  Future<String?> getValue(String key) async {
    final row = await (select(appSettings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// Insert or update a setting.
  Future<void> setValue(String key, String value) =>
      into(appSettings).insertOnConflictUpdate(
        AppSettingsCompanion(key: Value(key), value: Value(value)),
      );

  /// Delete a setting by [key]. Returns the number of deleted rows.
  Future<int> deleteKey(String key) =>
      (delete(appSettings)..where((s) => s.key.equals(key))).go();
}

