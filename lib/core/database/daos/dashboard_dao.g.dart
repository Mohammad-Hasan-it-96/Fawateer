// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_dao.dart';

// ignore_for_file: type=lint
mixin _$DashboardDaoMixin on DatabaseAccessor<AppDatabase> {
  $SalesInvoicesTable get salesInvoices => attachedDatabase.salesInvoices;
  $SalesItemsTable get salesItems => attachedDatabase.salesItems;
  $ProductsTable get products => attachedDatabase.products;
  $CashboxTransactionsTable get cashboxTransactions =>
      attachedDatabase.cashboxTransactions;
  $LedgerEntriesTable get ledgerEntries => attachedDatabase.ledgerEntries;
  $CustomersTable get customers => attachedDatabase.customers;
  DashboardDaoManager get managers => DashboardDaoManager(this);
}

class DashboardDaoManager {
  final _$DashboardDaoMixin _db;
  DashboardDaoManager(this._db);
  $$SalesInvoicesTableTableManager get salesInvoices =>
      $$SalesInvoicesTableTableManager(_db.attachedDatabase, _db.salesInvoices);
  $$SalesItemsTableTableManager get salesItems =>
      $$SalesItemsTableTableManager(_db.attachedDatabase, _db.salesItems);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$CashboxTransactionsTableTableManager get cashboxTransactions =>
      $$CashboxTransactionsTableTableManager(
          _db.attachedDatabase, _db.cashboxTransactions);
  $$LedgerEntriesTableTableManager get ledgerEntries =>
      $$LedgerEntriesTableTableManager(_db.attachedDatabase, _db.ledgerEntries);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
}
