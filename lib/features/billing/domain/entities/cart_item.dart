import 'package:equatable/equatable.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';

class CartItem extends Equatable {
  final Product product;

  /// Units being sold. A `double` so weight/fractional items (0.5 kg) work —
  /// matches `Product.quantity` and `salesItems.quantity` in the DB.
  final double quantity;

  const CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get total => product.price * quantity;

  CartItem copyWith({
    Product? product,
    double? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object> get props => [product, quantity];
}
