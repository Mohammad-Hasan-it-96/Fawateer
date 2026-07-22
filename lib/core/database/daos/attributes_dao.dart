import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/attribute_definitions_table.dart';

part 'attributes_dao.g.dart';

/// Reads/writes the owner-defined custom-field metadata (Plan 010).
/// Product *values* ride on `products.attributes` and are handled by
/// `ProductsDao`/`ProductRepository`; this DAO owns only the definitions.
@DriftAccessor(tables: [AttributeDefinitions])
class AttributesDao extends DatabaseAccessor<AppDatabase>
    with _$AttributesDaoMixin {
  AttributesDao(super.db);

  /// All definitions ordered for display (sortOrder then label).
  Future<List<AttributeDefinitionRow>> getAll() =>
      (select(attributeDefinitions)
            ..orderBy([
              (t) => OrderingTerm(expression: t.sortOrder),
              (t) => OrderingTerm(expression: t.label),
            ]))
          .get();

  /// Reactive stream of all definitions (archived included; callers filter).
  Stream<List<AttributeDefinitionRow>> watchAll() =>
      (select(attributeDefinitions)
            ..orderBy([
              (t) => OrderingTerm(expression: t.sortOrder),
              (t) => OrderingTerm(expression: t.label),
            ]))
          .watch();

  /// Insert or replace a definition by id.
  Future<void> upsert(AttributeDefinitionsCompanion def) =>
      into(attributeDefinitions).insert(def, mode: InsertMode.insertOrReplace);

  /// Insert many definitions in one transaction (used to seed a template).
  Future<void> insertAll(List<AttributeDefinitionsCompanion> defs) =>
      batch((b) => b.insertAll(attributeDefinitions, defs,
          mode: InsertMode.insertOrReplace));

  /// Hard-delete a definition by id. Callers guard with soft-archive when the
  /// field is in use on existing products.
  Future<int> deleteById(String id) =>
      (delete(attributeDefinitions)..where((t) => t.id.equals(id))).go();

  /// How many definitions currently exist (used to run onboarding only once).
  Future<int> count() async {
    final rows = await select(attributeDefinitions).get();
    return rows.length;
  }
}
