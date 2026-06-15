import 'package:drift/drift.dart';

@DataClassName('SalesItemRow')
class SalesItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceId => text()();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  RealColumn get price => real()();
  RealColumn get cost => real().withDefault(const Constant(0))();
  IntColumn get quantity => integer()();
}

