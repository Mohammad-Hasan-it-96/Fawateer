import 'package:equatable/equatable.dart';

import 'unit_status.dart';

/// One physical item of a serialized SKU (Plan 012).
///
/// A phone shop holding five "iPhone 15 128GB Black" has one [Product] and five
/// [ProductUnit]s. The SKU carries name/price/cost; the unit carries the IMEI,
/// where it is, and — once sold — which invoice sold it.
class ProductUnit extends Equatable {
  final String id;
  final String productId;

  /// The IMEI / serial number. Unique across the shop among non-empty values.
  final String serial;

  final UnitStatus status;

  /// The invoice that sold this unit; empty while unsold.
  final String soldInvoiceId;

  /// When it sold; null while unsold.
  final DateTime? soldAt;

  /// Warranty expiry; null when none was recorded.
  final DateTime? warrantyUntil;

  final String note;
  final DateTime createdAt;

  const ProductUnit({
    required this.id,
    required this.productId,
    required this.serial,
    this.status = UnitStatus.inStock,
    this.soldInvoiceId = '',
    this.soldAt,
    this.warrantyUntil,
    this.note = '',
    required this.createdAt,
  });

  /// True when this unit is on the shelf and can be sold.
  bool get isAvailable => status.isAvailable;

  /// Whether the warranty is still live **at [now]**.
  ///
  /// [now] is a parameter rather than a `DateTime.now()` call so this stays a
  /// pure function — the boundary (expires today vs expired yesterday) is the
  /// kind of thing that must be testable without a clock.
  bool isUnderWarrantyAt(DateTime now) {
    final until = warrantyUntil;
    if (until == null) return false;
    // Inclusive: a warranty "until the 30th" is still good *on* the 30th.
    return !now.isAfter(until);
  }

  ProductUnit copyWith({
    String? id,
    String? productId,
    String? serial,
    UnitStatus? status,
    String? soldInvoiceId,
    DateTime? soldAt,
    DateTime? warrantyUntil,
    String? note,
    DateTime? createdAt,
  }) =>
      ProductUnit(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        serial: serial ?? this.serial,
        status: status ?? this.status,
        soldInvoiceId: soldInvoiceId ?? this.soldInvoiceId,
        soldAt: soldAt ?? this.soldAt,
        warrantyUntil: warrantyUntil ?? this.warrantyUntil,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [
        id,
        productId,
        serial,
        status,
        soldInvoiceId,
        soldAt,
        warrantyUntil,
        note,
        createdAt,
      ];
}
