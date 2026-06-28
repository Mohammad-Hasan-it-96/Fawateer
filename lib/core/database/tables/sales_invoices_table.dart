import 'package:drift/drift.dart';

@DataClassName('SalesInvoiceRow')
class SalesInvoices extends Table {
  TextColumn get id => text()();
  /// Stored as milliseconds since epoch.
  IntColumn get createdAt => integer()();
  RealColumn get totalAmount => real()();
  // Note: the removed `customerId`/`customerName` columns are left orphaned in
  // existing databases (ignored by Drift, like the old `stock`/`upiId`) — no
  // migration needed since dropping a column requires none.

  @override
  Set<Column> get primaryKey => {id};
}

