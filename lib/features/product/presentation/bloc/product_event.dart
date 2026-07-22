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
