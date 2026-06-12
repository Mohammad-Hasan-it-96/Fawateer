import 'package:drift/drift.dart';

@DataClassName('DebtRow')
class Debts extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text()();
  RealColumn get amount => real()();
  /// Stored as milliseconds since epoch.
  IntColumn get date => integer()();
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

