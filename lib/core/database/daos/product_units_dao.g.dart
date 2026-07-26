// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_units_dao.dart';

// ignore_for_file: type=lint
mixin _$ProductUnitsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProductUnitsTable get productUnits => attachedDatabase.productUnits;
  $ProductsTable get products => attachedDatabase.products;
  ProductUnitsDaoManager get managers => ProductUnitsDaoManager(this);
}

class ProductUnitsDaoManager {
  final _$ProductUnitsDaoMixin _db;
  ProductUnitsDaoManager(this._db);
  $$ProductUnitsTableTableManager get productUnits =>
      $$ProductUnitsTableTableManager(_db.attachedDatabase, _db.productUnits);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
}
