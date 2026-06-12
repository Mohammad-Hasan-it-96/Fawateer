import 'package:drift/drift.dart';

/// Key-value store table for app settings (e.g. printer_mac, printer_name).
@DataClassName('SettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

