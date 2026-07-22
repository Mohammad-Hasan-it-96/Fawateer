import 'package:equatable/equatable.dart';

import '../../../../core/attributes/product_attributes.dart';
import 'price_currency.dart';
import 'product_sale_type.dart';

class Product extends Equatable {
  final String
      id; // Using barcode as ID usually, but keeping separate ID is safer
  final String name;
  final String barcode;
  final double price; // per-piece price, or per-kg price when sold by weight
  final double cost; // purchase cost, for margin/profit reporting
  final double quantity; // on-hand inventory (was stock); supports weight/fractions
  final double minStockAlert; // low-stock threshold; 0 = no alert
  final ProductSaleType saleType; // piece (default) vs a measured type (weight)
  final PriceCurrency priceCurrency; // currency of price/cost (SP base, or USD)
  final ProductAttributes attributes; // owner-defined custom fields (Plan 010)

  const Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    this.cost = 0,
    this.quantity = 0,
    this.minStockAlert = 0,
    this.saleType = ProductSaleType.piece,
    this.priceCurrency = PriceCurrency.sp,
    this.attributes = ProductAttributes.empty,
  });

  /// True when a low-stock alert is set and on-hand has reached it.
  bool get isLowStock => minStockAlert > 0 && quantity <= minStockAlert;

  Product copyWith({
    String? id,
    String? name,
    String? barcode,
    double? price,
    double? cost,
    double? quantity,
    double? minStockAlert,
    ProductSaleType? saleType,
    PriceCurrency? priceCurrency,
    ProductAttributes? attributes,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      quantity: quantity ?? this.quantity,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      saleType: saleType ?? this.saleType,
      priceCurrency: priceCurrency ?? this.priceCurrency,
      attributes: attributes ?? this.attributes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        barcode,
        price,
        cost,
        quantity,
        minStockAlert,
        saleType,
        priceCurrency,
        attributes,
      ];
}
