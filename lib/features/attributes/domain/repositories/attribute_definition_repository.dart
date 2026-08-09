import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/attribute_definition.dart';

/// Owner-defined custom product fields (Plan 010, bucket A). Manages only the
/// field *metadata*; per-product values live on `Product.attributes`.
abstract class AttributeDefinitionRepository {
  /// Reactive stream of all definitions (archived included — callers filter).
  Stream<List<AttributeDefinition>> watchDefinitions();

  Future<Either<Failure, List<AttributeDefinition>>> getDefinitions();

  /// Create or update a definition (by id).
  Future<Either<Failure, void>> save(AttributeDefinition definition);

  /// Hard-delete a definition by id (caller soft-archives when it's in use).
  Future<Either<Failure, void>> delete(String id);

  /// Seed a batch of definitions in one transaction (used by templates).
  Future<Either<Failure, void>> saveAll(List<AttributeDefinition> definitions);

  /// Whether any definition exists yet (drives one-time onboarding).
  Future<Either<Failure, bool>> hasAny();

  /// Rename one `select` option **and move every product holding it**
  /// (Plan 014 step 3). Returns how many products moved.
  ///
  /// Renaming onto an option that already exists is a **merge**, not a
  /// duplicate: the owner tidying "مشروبات" into an existing "عصائر" means the
  /// two become one, which is exactly what they intended.
  Future<Either<Failure, int>> renameOption({
    required String definitionId,
    required String from,
    required String to,
  });

  /// Delete one `select` option **and clear it from every product holding it**.
  /// Those products fall into the "no value" bucket rather than keeping a value
  /// that is no longer offered. Returns how many products were cleared.
  Future<Either<Failure, int>> removeOption({
    required String definitionId,
    required String value,
  });
}
