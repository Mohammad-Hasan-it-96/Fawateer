import 'package:drift/drift.dart';

@DataClassName('SalesInvoiceRow')
class SalesInvoices extends Table {
  TextColumn get id => text()();
  /// Stored as milliseconds since epoch.
  IntColumn get createdAt => integer()();
  RealColumn get totalAmount => real()();
  TextColumn get customerId => text().nullable()();
  TextColumn get customerName => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

