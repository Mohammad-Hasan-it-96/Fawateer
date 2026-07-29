// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_dao.dart';

// ignore_for_file: type=lint
mixin _$StockDaoMixin on DatabaseAccessor<AppDatabase> {
  $StockMovementsTable get stockMovements => attachedDatabase.stockMovements;
  $ProductsTable get products => attachedDatabase.products;
  StockDaoManager get managers => StockDaoManager(this);
}

class StockDaoManager {
  final _$StockDaoMixin _db;
  StockDaoManager(this._db);
  $$StockMovementsTableTableManager get stockMovements =>
      $$StockMovementsTableTableManager(
          _db.attachedDatabase, _db.stockMovements);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
}
