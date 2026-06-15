import 'package:drift/drift.dart';

@DataClassName('ProductRow')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get barcode => text().withDefault(const Constant(''))();
  RealColumn get price => real()();
  RealColumn get cost => real().withDefault(const Constant(0))();
  IntColumn get stock => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

