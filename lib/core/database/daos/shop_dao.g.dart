// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_dao.dart';

// ignore_for_file: type=lint
mixin _$ShopDaoMixin on DatabaseAccessor<AppDatabase> {
  $ShopSettingsTable get shopSettings => attachedDatabase.shopSettings;
  ShopDaoManager get managers => ShopDaoManager(this);
}

class ShopDaoManager {
  final _$ShopDaoMixin _db;
  ShopDaoManager(this._db);
  $$ShopSettingsTableTableManager get shopSettings =>
      $$ShopSettingsTableTableManager(_db.attachedDatabase, _db.shopSettings);
}
