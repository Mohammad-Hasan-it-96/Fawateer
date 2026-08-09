// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attributes_dao.dart';

// ignore_for_file: type=lint
mixin _$AttributesDaoMixin on DatabaseAccessor<AppDatabase> {
  $AttributeDefinitionsTable get attributeDefinitions =>
      attachedDatabase.attributeDefinitions;
  $ProductsTable get products => attachedDatabase.products;
  AttributesDaoManager get managers => AttributesDaoManager(this);
}

class AttributesDaoManager {
  final _$AttributesDaoMixin _db;
  AttributesDaoManager(this._db);
  $$AttributeDefinitionsTableTableManager get attributeDefinitions =>
      $$AttributeDefinitionsTableTableManager(
          _db.attachedDatabase, _db.attributeDefinitions);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
}
