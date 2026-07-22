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
}
