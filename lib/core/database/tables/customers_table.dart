import 'package:drift/drift.dart';

@DataClassName('CustomerRow')
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

