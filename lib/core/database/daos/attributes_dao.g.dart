// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attributes_dao.dart';

// ignore_for_file: type=lint
mixin _$AttributesDaoMixin on DatabaseAccessor<AppDatabase> {
  $AttributeDefinitionsTable get attributeDefinitions =>
      attachedDatabase.attributeDefinitions;
  AttributesDaoManager get managers => AttributesDaoManager(this);
}

class AttributesDaoManager {
  final _$AttributesDaoMixin _db;
  AttributesDaoManager(this._db);
  $$AttributeDefinitionsTableTableManager get attributeDefinitions =>
      $$AttributeDefinitionsTableTableManager(
          _db.attachedDatabase, _db.attributeDefinitions);
}
