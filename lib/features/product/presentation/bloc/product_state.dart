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

  /// A bulk price/cost edit landed; [ProductState.messageCount] holds how many
  /// products actually changed.
  bulkPricesUpdated,

  /// The bulk edit resolved to no change at all (everything was already at that
  /// price, or every selected product had been deleted). Deliberately its own
  /// message: a green "done" after nothing happened is how a shop ends up
  /// believing a price change was saved when it was not.
  bulkPricesUnchanged,

  /// A bulk category assign landed; [ProductState.messageCount] holds how many
  /// products moved.
  bulkCategorySet,
}

class ProductState extends Equatable {
  final ProductStatus status;
  final List<Product> products;

  /// Transient one-shot feedback (success or error). Cleared on the next emit
  /// unless explicitly set, so it can't re-trigger a snackbar.
  final ProductMessage? message;

  /// How many rows a bulk action touched, for the message that reports it.
  /// Transient like [message] — cleared on the next emit.
  final int messageCount;

  const ProductState({
    this.status = ProductStatus.initial,
    this.products = const [],
    this.message,
    this.messageCount = 0,
  });

  ProductState copyWith({
    ProductStatus? status,
    List<Product>? products,
    ProductMessage? message,
    int messageCount = 0,
  }) {
    return ProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      message: message,
      messageCount: messageCount,
    );
  }

  @override
  List<Object?> get props => [status, products, message, messageCount];
}
