import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/product_units_dao.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/sync/sync_clock.dart';
import '../../domain/entities/product_unit.dart';
import '../../domain/entities/unit_status.dart';
import '../../domain/repositories/product_unit_repository.dart';

class ProductUnitRepositoryDriftImpl implements ProductUnitRepository {
  final ProductUnitsDao _dao;
  final SyncClock _clock;
  const ProductUnitRepositoryDriftImpl(this._dao, this._clock);

  // ── mapping helpers ───────────────────────────────────────────────────────

  /// 0 is the table's "unset" sentinel for both timestamps (see the table doc),
  /// so it maps back to null rather than to 1970.
  static DateTime? _time(int ms) =>
      ms == 0 ? null : DateTime.fromMillisecondsSinceEpoch(ms);

  static ProductUnit _toEntity(ProductUnitRow row) => ProductUnit(
        id: row.id,
        productId: row.productId,
        serial: row.serial,
        status: UnitStatus.fromName(row.status),
        soldInvoiceId: row.soldInvoiceId,
        soldAt: _time(row.soldAt),
        warrantyUntil: _time(row.warrantyUntil),
        note: row.note,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      );

  static ProductUnitsCompanion _toCompanion(ProductUnit u, SyncStamp stamp) =>
      ProductUnitsCompanion(
        id: Value(u.id),
        productId: Value(u.productId),
        serial: Value(u.serial.trim()),
        status: Value(u.status.name),
        soldInvoiceId: Value(u.soldInvoiceId),
        soldAt: Value(u.soldAt?.millisecondsSinceEpoch ?? 0),
        warrantyUntil: Value(u.warrantyUntil?.millisecondsSinceEpoch ?? 0),
        note: Value(u.note),
        createdAt: Value(u.createdAt.millisecondsSinceEpoch),
        // The sync stamp: without it `updated_at` stays '' and the row is
        // never pushed. See the note in ProductRepositoryDriftImpl.
        updatedAt: Value(stamp.hlc),
        originDevice: Value(stamp.device),
      );

  /// True when [e] is SQLite refusing a duplicate serial — the partial unique
  /// index doing its job, not an unexpected failure.
  ///
  /// Matched on the message rather than on `SqliteException.resultCode` so this
  /// layer doesn't take a direct dependency on `sqlite3` just to name a constant.
  /// It is only the **backstop**: [addUnit] checks for an existing serial first
  /// and reports the friendly error from there. This arm exists for the race
  /// where two units are added at once, where losing the report would let the
  /// insert fail as a generic "something went wrong".
  static bool _isUniqueViolation(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('unique') && s.contains('constraint');
  }

  // ── repository interface ──────────────────────────────────────────────────

  @override
  Stream<List<ProductUnit>> watchUnits(String productId) =>
      _dao.watchUnitsForProduct(productId).map(
            (rows) => rows.map(_toEntity).toList(),
          );

  @override
  Future<Either<Failure, List<ProductUnit>>> getUnits(String productId) async {
    try {
      final rows = await _dao.getUnitsForProduct(productId);
      return Right(rows.map(_toEntity).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductUnit>> findBySerial(String serial) async {
    try {
      final row = await _dao.getBySerial(serial.trim());
      if (row == null) {
        return const Left(NotFoundFailure('serial_not_found'));
      }
      return Right(_toEntity(row));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addUnit(ProductUnit unit) async {
    try {
      final serial = unit.serial.trim();
      // Checked up front so the common case reports cleanly, and so the message
      // can name the conflict rather than surfacing a raw constraint error. The
      // index below is still the authority — this is convenience, not the guard.
      if (serial.isNotEmpty && await _dao.getBySerial(serial) != null) {
        return const Left(DuplicateFailure('duplicate_serial'));
      }
      await _dao.insertUnit(_toCompanion(unit, await _clock.stamp()));
      return const Right(null);
    } catch (e) {
      // A duplicate serial is an expected outcome the cashier must be told
      // about, not an "unexpected error" — the whole point of the unique index
      // is that the shop can't hold two rows for one handset.
      if (_isUniqueViolation(e)) {
        return const Left(DuplicateFailure('duplicate_serial'));
      }
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUnit(String id) async {
    try {
      final rows = await _dao.getUnitById(id);
      if (rows == null) return const Left(NotFoundFailure('unit_not_found'));
      if (rows.status == UnitStatus.sold.name) {
        // This row is the serial → invoice link a warranty claim depends on.
        // Losing it silently is exactly the failure this feature exists to
        // prevent, so refuse rather than delete history.
        return const Left(ConflictFailure('unit_already_sold'));
      }
      await _dao.softDeleteUnit(id, await _clock.stamp());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setStatus(String id, UnitStatus status) async {
    try {
      await _dao.updateStatus(id, status.name, await _clock.stamp());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setWarranty(String id, DateTime? until) async {
    try {
      await _dao.setWarranty(
          id, until?.millisecondsSinceEpoch ?? 0, await _clock.stamp());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> availableCount(String productId) async {
    try {
      return Right(await _dao.availableCount(productId));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
