part of 'product_unit_bloc.dart';

/// One-shot outcomes the page turns into a localized snackbar. Typed, never
/// pre-rendered English — the page owns the wording (see CLAUDE.md).
enum UnitMessage {
  added,
  saved,
  deleted,
  loadFailed,
  saveFailed,

  /// The serial is already on file. An IMEI identifies one handset, so a second
  /// row for it would let the shop sell the same phone twice.
  duplicateSerial,

  /// Refused: the unit has already been sold, and its row is the serial →
  /// invoice link a warranty claim depends on.
  deleteBlockedSold,
}

class ProductUnitState extends Equatable {
  final String productId;
  final List<ProductUnit> units;
  final bool loading;

  /// Transient; cleared by [ClearUnitMessage] after the page reacts.
  final UnitMessage? message;

  const ProductUnitState({
    this.productId = '',
    this.units = const [],
    this.loading = false,
    this.message,
  });

  /// Units still on the shelf — what the SKU's cached `quantity` mirrors.
  List<ProductUnit> get available =>
      units.where((u) => u.isAvailable).toList();

  int get availableCount => available.length;

  ProductUnitState copyWith({
    String? productId,
    List<ProductUnit>? units,
    bool? loading,
    UnitMessage? message,
    bool clearMessage = false,
  }) =>
      ProductUnitState(
        productId: productId ?? this.productId,
        units: units ?? this.units,
        loading: loading ?? this.loading,
        // A plain copyWith clears the message, so a state change unrelated to
        // the last action can't re-fire its snackbar.
        message: clearMessage ? null : message,
      );

  @override
  List<Object?> get props => [productId, units, loading, message];
}
