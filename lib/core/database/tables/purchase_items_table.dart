import 'package:drift/drift.dart';

@DataClassName('PurchaseItemRow')
class PurchaseItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceId => text()();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  RealColumn get cost => real()();
  IntColumn get quantity => integer()();
}

