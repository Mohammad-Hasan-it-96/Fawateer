import 'package:equatable/equatable.dart';
import 'package:billing_app/features/product/domain/entities/price_currency.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';

class CartItem extends Equatable {
  final Product product;

  /// Units being sold. A `double` so weight/fractional items (0.5 kg) work —
  /// matches `Product.quantity` and `salesItems.quantity` in the DB.
  final double quantity;

  /// Resolved **SP** unit price (per piece, or per-kg for a weighed item). For
  /// an SP product this equals `product.price`; for a USD product it's the
  /// price converted to whole SP at [fxRate]. The whole app settles in SP, so
  /// every downstream total is built from this — never from `product.price`.
  final double unitPriceSp;

  /// Resolved SP unit cost (snapshot for profit reporting).
  final double unitCostSp;

  /// SP-per-USD rate used to resolve a foreign line; 0 for an SP-native line.
  /// Also the guard signal: a foreign line with fxRate 0 is *unpriced* (no rate
  /// set yet) and blocks checkout.
  final double fxRate;

  /// Manual per-line discount in SP (the resolved amount, whether entered as a %
  /// or a fixed value). 0 = none. Clamped to the line subtotal via
  /// [effectiveDiscount] so a stored value can't exceed the line or go negative.
  final double discount;

  const CartItem({
    required this.product,
    this.quantity = 1,
    required this.unitPriceSp,
    this.unitCostSp = 0,
    this.fxRate = 0,
    this.discount = 0,
  });

  /// Line subtotal (SP) before the discount.
  double get gross => unitPriceSp * quantity;

  /// The discount actually applied — never negative, never more than [gross]
  /// (so reducing quantity below the discount can't make the line negative).
  double get effectiveDiscount =>
      discount <= 0 ? 0 : (discount > gross ? gross : discount);

  /// Line total in SP, net of the discount.
  double get total => gross - effectiveDiscount;

  /// True when the product is priced in a non-base currency (needs conversion).
  bool get isForeign => product.priceCurrency.isForeign;

  /// True when this is a foreign line that couldn't be priced (no valid rate).
  bool get isUnpriced => isForeign && fxRate <= 0;

  PriceCurrency get sellCurrency => product.priceCurrency;

  CartItem copyWith({
    Product? product,
    double? quantity,
    double? unitPriceSp,
    double? unitCostSp,
    double? fxRate,
    double? discount,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPriceSp: unitPriceSp ?? this.unitPriceSp,
      unitCostSp: unitCostSp ?? this.unitCostSp,
      fxRate: fxRate ?? this.fxRate,
      discount: discount ?? this.discount,
    );
  }

  @override
  List<Object> get props =>
      [product, quantity, unitPriceSp, unitCostSp, fxRate, discount];
}
