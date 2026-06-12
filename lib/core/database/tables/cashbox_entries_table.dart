import 'package:drift/drift.dart';

@DataClassName('CashboxRow')
class CashboxEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  /// 'income' or 'expense'
  TextColumn get type => text()();
  /// Stored as milliseconds since epoch.
  IntColumn get date => integer()();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

