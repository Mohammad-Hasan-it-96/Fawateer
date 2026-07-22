part of 'product_bloc.dart';

enum ProductStatus { initial, loading, loaded, error, success }

/// Localizable feedback for a product action; the page maps it to a string so
/// no user-facing English lives in the BLoC.
enum ProductMessage {
  added,
  updated,
  deleted,
  barcodeExists,
  saveFailed,
  loadFailed,
  labelPrinted,
  labelPrintFailed,
}

class ProductState extends Equatable {
  final ProductStatus status;
  final List<Product> products;

  /// Transient one-shot feedback (success or error). Cleared on the next emit
  /// unless explicitly set, so it can't re-trigger a snackbar.
  final ProductMessage? message;

  const ProductState({
    this.status = ProductStatus.initial,
    this.products = const [],
    this.message,
  });

  ProductState copyWith({
    ProductStatus? status,
    List<Product>? products,
    ProductMessage? message,
  }) {
    return ProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, products, message];
}
