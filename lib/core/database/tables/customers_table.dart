import 'package:drift/drift.dart';

import 'sync_meta.dart';

@DataClassName('CustomerRow')
class Customers extends Table with SyncMeta {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();

  /// Stored as milliseconds since epoch.
  IntColumn get createdAt => integer()();

  /// Soft-hide a customer without deleting their ledger history.
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
