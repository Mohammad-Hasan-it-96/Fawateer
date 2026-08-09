part of 'product_bloc.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object> get props => [];
}

class LoadProducts extends ProductEvent {}

class AddProduct extends ProductEvent {
  final Product product;
  const AddProduct(this.product);
  @override
  List<Object> get props => [product];
}

class UpdateProduct extends ProductEvent {
  final Product product;
  const UpdateProduct(this.product);
  @override
  List<Object> get props => [product];
}

class DeleteProduct extends ProductEvent {
  final String id;
  const DeleteProduct(this.id);
  @override
  List<Object> get props => [id];
}

/// Apply one price/cost change to many products at once (Plan 015 B2.2).
///
/// Carries the **ids**, not the product objects: the list is stream-backed, so
/// by the time this runs the page's copies may be a frame or two old. The BLoC
/// resolves the ids against its own current products and silently skips any
/// that were deleted meanwhile.
class BulkUpdatePrices extends ProductEvent {
  final Set<String> productIds;
  final BulkPriceEdit edit;
  const BulkUpdatePrices({required this.productIds, required this.edit});
  @override
  List<Object> get props => [productIds, edit.field, edit.mode, edit.value];
}

/// Put many products into one category at once (Plan 014 step 2). A blank
/// [value] clears the field — "move these back to no category".
///
/// Carries ids for the same reason as [BulkUpdatePrices]: the list is live.
class BulkSetAttribute extends ProductEvent {
  final Set<String> productIds;
  final String definitionId;
  final String value;
  const BulkSetAttribute({
    required this.productIds,
    required this.definitionId,
    required this.value,
  });
  @override
  List<Object> get props => [productIds, definitionId, value];
}

/// Print one or more thermal labels for a product (Plan 010). The page resolves
/// the display price string (currency-aware) and the code type/copies.
class PrintProductLabel extends ProductEvent {
  final String name;
  final String priceText;
  final String barcodeData;
  final bool useQr;
  final int copies;
  const PrintProductLabel({
    required this.name,
    required this.priceText,
    required this.barcodeData,
    this.useQr = false,
    this.copies = 1,
  });
  @override
  List<Object> get props => [name, priceText, barcodeData, useQr, copies];
}
