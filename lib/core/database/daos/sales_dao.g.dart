// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_dao.dart';

// ignore_for_file: type=lint
mixin _$SalesDaoMixin on DatabaseAccessor<AppDatabase> {
  $SalesInvoicesTable get salesInvoices => attachedDatabase.salesInvoices;
  $SalesItemsTable get salesItems => attachedDatabase.salesItems;
  $LedgerEntriesTable get ledgerEntries => attachedDatabase.ledgerEntries;
  $CashboxTransactionsTable get cashboxTransactions =>
      attachedDatabase.cashboxTransactions;
  $CustomersTable get customers => attachedDatabase.customers;
  $ProductsTable get products => attachedDatabase.products;
  SalesDaoManager get managers => SalesDaoManager(this);
}

class SalesDaoManager {
  final _$SalesDaoMixin _db;
  SalesDaoManager(this._db);
  $$SalesInvoicesTableTableManager get salesInvoices =>
      $$SalesInvoicesTableTableManager(_db.attachedDatabase, _db.salesInvoices);
  $$SalesItemsTableTableManager get salesItems =>
      $$SalesItemsTableTableManager(_db.attachedDatabase, _db.salesItems);
  $$LedgerEntriesTableTableManager get ledgerEntries =>
      $$LedgerEntriesTableTableManager(_db.attachedDatabase, _db.ledgerEntries);
  $$CashboxTransactionsTableTableManager get cashboxTransactions =>
      $$CashboxTransactionsTableTableManager(
          _db.attachedDatabase, _db.cashboxTransactions);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
}
