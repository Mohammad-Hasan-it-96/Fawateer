import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/attributes_dao.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/sync/sync_clock.dart';
import '../../domain/entities/attribute_definition.dart';
import '../../domain/entities/attribute_type.dart';
import '../../domain/repositories/attribute_definition_repository.dart';

class AttributeDefinitionRepositoryDriftImpl
    implements AttributeDefinitionRepository {
  final AttributesDao _dao;
  final SyncClock _clock;

  const AttributeDefinitionRepositoryDriftImpl(this._dao, this._clock);

  // ── mapping ────────────────────────────────────────────────────────────────

  static AttributeDefinition _toEntity(AttributeDefinitionRow row) =>
      AttributeDefinition(
        id: row.id,
        label: row.label,
        type: AttributeType.fromName(row.type),
        options: _decodeOptions(row.options),
        unit: row.unit,
        isRequired: row.isRequired,
        showInList: row.showInList,
        showOnReceipt: row.showOnReceipt,
        sortOrder: row.sortOrder,
        isArchived: row.isArchived,
      );

  static AttributeDefinitionsCompanion _toCompanion(AttributeDefinition d) =>
      AttributeDefinitionsCompanion(
        id: Value(d.id),
        label: Value(d.label),
        type: Value(d.type.name),
        options: Value(d.options.isEmpty ? '' : jsonEncode(d.options)),
        unit: Value(d.unit),
        isRequired: Value(d.isRequired),
        showInList: Value(d.showInList),
        showOnReceipt: Value(d.showOnReceipt),
        sortOrder: Value(d.sortOrder),
        isArchived: Value(d.isArchived),
      );

  /// Defensive: a null/blank/garbled options column decodes to an empty list.
  static List<String> _decodeOptions(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }

  // ── interface ────────────────────────────────────────────────────────────

  @override
  Stream<List<AttributeDefinition>> watchDefinitions() =>
      _dao.watchAll().map((rows) => rows.map(_toEntity).toList());

  @override
  Future<Either<Failure, List<AttributeDefinition>>> getDefinitions() async {
    try {
      final rows = await _dao.getAll();
      return Right(rows.map(_toEntity).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> save(AttributeDefinition definition) async {
    try {
      await _dao.upsert(_toCompanion(definition));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveAll(
      List<AttributeDefinition> definitions) async {
    try {
      await _dao.insertAll(definitions.map(_toCompanion).toList());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await _dao.softDeleteById(id, await _clock.stamp());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> hasAny() async {
    try {
      final n = await _dao.count();
      return Right(n > 0);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
