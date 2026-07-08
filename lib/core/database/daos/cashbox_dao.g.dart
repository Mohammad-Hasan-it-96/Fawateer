// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cashbox_dao.dart';

// ignore_for_file: type=lint
mixin _$CashboxDaoMixin on DatabaseAccessor<AppDatabase> {
  $CashboxTransactionsTable get cashboxTransactions =>
      attachedDatabase.cashboxTransactions;
  CashboxDaoManager get managers => CashboxDaoManager(this);
}

class CashboxDaoManager {
  final _$CashboxDaoMixin _db;
  CashboxDaoManager(this._db);
  $$CashboxTransactionsTableTableManager get cashboxTransactions =>
      $$CashboxTransactionsTableTableManager(
          _db.attachedDatabase, _db.cashboxTransactions);
}
