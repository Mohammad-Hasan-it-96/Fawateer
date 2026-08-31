import 'package:drift/drift.dart';
import '../../sync/sync_clock.dart';
import '../app_database.dart';
import '../tables/attribute_definitions_table.dart';
import '../tables/products_table.dart';

part 'attributes_dao.g.dart';

/// Reads/writes the owner-defined custom-field metadata (Plan 010).
/// Product *values* ride on `products.attributes` and are handled by
/// `ProductsDao`/`ProductRepository`; this DAO owns only the definitions —
/// **except** for the option rename/remove pair below, which has to move the
/// stored values with the option or the products silently leave the category
/// (Plan 014 step 3). `Products` is in the accessor list for that reason alone,
/// the same reason `SalesDao` carries it: so the write can name the table and
/// `watchAllProducts` re-runs.
@DriftAccessor(tables: [AttributeDefinitions, Products])
class AttributesDao extends DatabaseAccessor<AppDatabase>
    with _$AttributesDaoMixin {
  AttributesDao(super.db);

  /// All definitions ordered for display (sortOrder then label).
  Future<List<AttributeDefinitionRow>> getAll() =>
      (select(attributeDefinitions)
            ..where((t) => t.deletedAt.equals(''))
            ..orderBy([
              (t) => OrderingTerm(expression: t.sortOrder),
              (t) => OrderingTerm(expression: t.label),
            ]))
          .get();

  /// Reactive stream of all definitions (archived included; callers filter).
  Stream<List<AttributeDefinitionRow>> watchAll() =>
      (select(attributeDefinitions)
            ..where((t) => t.deletedAt.equals(''))
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

  /// Tombstone a definition by id. Callers guard with soft-archive when the
  /// field is in use on existing products.
  Future<int> softDeleteById(String id, SyncStamp stamp) =>
      (update(attributeDefinitions)
            ..where((t) => t.id.equals(id) & t.deletedAt.equals('')))
          .write(AttributeDefinitionsCompanion(
        deletedAt: Value(stamp.hlc),
        updatedAt: Value(stamp.hlc),
        originDevice: Value(stamp.device),
      ));

  /// How many definitions currently exist (used to run onboarding only once).
  ///
  /// Counts live rows: a shop that deleted every field it created should be
  /// offered onboarding again, not left staring at an empty screen.
  Future<int> count() async {
    final rows = await (select(attributeDefinitions)
          ..where((t) => t.deletedAt.equals('')))
        .get();
    return rows.length;
  }

  // ── select options that carry their products with them (Plan 014 step 3) ────
  //
  // A `select` option's value is a **string copied into every product's JSON
  // bag**. Editing the option list alone therefore leaves every product holding
  // a value that is no longer on the list: the products are not lost, but they
  // vanish from their category, which looks exactly like data loss. Both writes
  // below are one transaction for that reason — a half-done rename is worse
  // than no rename.
  //
  // `json_valid` guards the empty/legacy `attributes` default (`''`), which is
  // not JSON; `json_extract` would error on it otherwise. The JSON path is a
  // **bound parameter**, following `DashboardDao.salesByAttribute`.

  // (There is no "count products using this option" query here on purpose: the
  // product list is already held in full, live, by `ProductBloc`, so the
  // confirmation dialog counts in memory rather than round-tripping the DB for
  // a number it is already holding.)

  /// Rename one option and move every product holding it, in one transaction.
  /// Returns how many products moved.
  ///
  /// [newOptionsJson] is the already-encoded replacement option list — the
  /// repository owns the merge rule (renaming onto an option that already
  /// exists folds the two together rather than listing it twice).
  Future<int> renameOptionEverywhere({
    required String definitionId,
    required String newOptionsJson,
    required String jsonPath,
    required String from,
    required String to,
    required SyncStamp stamp,
  }) {
    return transaction(() async {
      await (update(attributeDefinitions)
            ..where((t) => t.id.equals(definitionId)))
          .write(AttributeDefinitionsCompanion(
        options: Value(newOptionsJson),
        updatedAt: Value(stamp.hlc),
        originDevice: Value(stamp.device),
      ));
        // Both the definition and every product row it rewrites are stamped.
        // A bulk rewrite is still an edit: unstamped, the renamed values sit
        // below the push watermark and the other till keeps showing the old
        // option forever, with nothing having failed.
      return customUpdate(
        'UPDATE products SET attributes = json_set(attributes, ?, ?), '
        'updated_at = ?, origin_device = ? '
        'WHERE json_valid(attributes) AND json_extract(attributes, ?) = ?',
        variables: [
          Variable.withString(jsonPath),
          Variable.withString(to),
          Variable.withString(stamp.hlc),
          Variable.withString(stamp.device),
          Variable.withString(jsonPath),
          Variable.withString(from),
        ],
        updates: {products},
      );
    });
  }

  /// Delete one option and clear it from every product holding it, in one
  /// transaction. Returns how many products were cleared.
  ///
  /// Clearing — not blocking — is the deliberate choice: those products land in
  /// the "no category" bucket, which the UI shows as its own chip, so they stay
  /// findable. Refusing the delete instead would strand the owner with a
  /// category they no longer use and cannot remove.
  Future<int> removeOptionEverywhere({
    required String definitionId,
    required String newOptionsJson,
    required String jsonPath,
    required String value,
    required SyncStamp stamp,
  }) {
    return transaction(() async {
      await (update(attributeDefinitions)
            ..where((t) => t.id.equals(definitionId)))
          .write(AttributeDefinitionsCompanion(
        options: Value(newOptionsJson),
        updatedAt: Value(stamp.hlc),
        originDevice: Value(stamp.device),
      ));
      // Collapse a bag that ends up empty back to '' rather than '{}', so the
      // column keeps the single "no attributes" representation the entity
      // writes (ProductAttributes.toJson).
        // Both the definition and every product row it rewrites are stamped.
        // A bulk rewrite is still an edit: unstamped, the renamed values sit
        // below the push watermark and the other till keeps showing the old
        // option forever, with nothing having failed.
      return customUpdate(
        "UPDATE products SET attributes = "
        "CASE WHEN json_remove(attributes, ?) = '{}' THEN '' "
        "     ELSE json_remove(attributes, ?) END, "
        'updated_at = ?, origin_device = ? '
        'WHERE json_valid(attributes) AND json_extract(attributes, ?) = ?',
        variables: [
          Variable.withString(jsonPath),
          Variable.withString(jsonPath),
          Variable.withString(stamp.hlc),
          Variable.withString(stamp.device),
          Variable.withString(jsonPath),
          Variable.withString(value),
        ],
        updates: {products},
      );
    });
  }
}
