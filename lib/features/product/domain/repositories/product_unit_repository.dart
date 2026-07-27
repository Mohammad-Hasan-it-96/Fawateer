import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/product_unit.dart';
import '../entities/unit_status.dart';

/// Serialized inventory (Plan 012) — the per-physical-item half of the product
/// feature. Descriptive per-SKU data stays on [Product]/`attributes`.
abstract class ProductUnitRepository {
  /// Live list of one SKU's units, newest first.
  Stream<List<ProductUnit>> watchUnits(String productId);

  Future<Either<Failure, List<ProductUnit>>> getUnits(String productId);

  /// Look one unit up by exact serial — the warranty question ("I bought this
  /// here, is it still covered?") and the POS's second scan path both land here.
  ///
  /// Returns [NotFoundFailure] when no unit carries that serial, so callers can
  /// tell "unknown serial" from "lookup failed".
  Future<Either<Failure, ProductUnit>> findBySerial(String serial);

  /// Add a unit to stock.
  ///
  /// Returns [DuplicateFailure] when the serial is already on file — an IMEI
  /// identifies one handset, so a second row for it would let the shop sell the
  /// same phone twice.
  Future<Either<Failure, void>> addUnit(ProductUnit unit);

  /// Remove a unit. Returns [ConflictFailure] for a unit that has already been
  /// sold: that row is the link between a serial and the invoice that sold it,
  /// and deleting it would silently break warranty lookup for a real customer.
  Future<Either<Failure, void>> deleteUnit(String id);

  Future<Either<Failure, void>> setStatus(String id, UnitStatus status);

  /// Set or clear (null) a unit's warranty expiry.
  Future<Either<Failure, void>> setWarranty(String id, DateTime? until);

  /// How many units of this SKU are on the shelf.
  Future<Either<Failure, int>> availableCount(String productId);
}
