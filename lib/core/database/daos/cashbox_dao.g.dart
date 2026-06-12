// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cashbox_dao.dart';

// ignore_for_file: type=lint
mixin _$CashboxDaoMixin on DatabaseAccessor<AppDatabase> {
  $CashboxEntriesTable get cashboxEntries => attachedDatabase.cashboxEntries;
  CashboxDaoManager get managers => CashboxDaoManager(this);
}

class CashboxDaoManager {
  final _$CashboxDaoMixin _db;
  CashboxDaoManager(this._db);
  $$CashboxEntriesTableTableManager get cashboxEntries =>
      $$CashboxEntriesTableTableManager(
          _db.attachedDatabase, _db.cashboxEntries);
}
