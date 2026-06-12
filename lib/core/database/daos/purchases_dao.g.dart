// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchases_dao.dart';

// ignore_for_file: type=lint
mixin _$PurchasesDaoMixin on DatabaseAccessor<AppDatabase> {
  $PurchaseInvoicesTable get purchaseInvoices =>
      attachedDatabase.purchaseInvoices;
  $PurchaseItemsTable get purchaseItems => attachedDatabase.purchaseItems;
  PurchasesDaoManager get managers => PurchasesDaoManager(this);
}

class PurchasesDaoManager {
  final _$PurchasesDaoMixin _db;
  PurchasesDaoManager(this._db);
  $$PurchaseInvoicesTableTableManager get purchaseInvoices =>
      $$PurchaseInvoicesTableTableManager(
          _db.attachedDatabase, _db.purchaseInvoices);
  $$PurchaseItemsTableTableManager get purchaseItems =>
      $$PurchaseItemsTableTableManager(_db.attachedDatabase, _db.purchaseItems);
}
