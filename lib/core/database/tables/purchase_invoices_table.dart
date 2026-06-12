import 'package:drift/drift.dart';

@DataClassName('PurchaseInvoiceRow')
class PurchaseInvoices extends Table {
  TextColumn get id => text()();
  /// Stored as milliseconds since epoch.
  IntColumn get createdAt => integer()();
  RealColumn get totalAmount => real()();
  TextColumn get supplier => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

