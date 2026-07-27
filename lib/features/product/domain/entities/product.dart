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

  /// Opt-in per-unit identity (Plan 012): this SKU's stock is tracked as
  /// individual units carrying an IMEI/serial each, so [quantity] becomes a
  /// maintained cache of how many are on the shelf rather than a number the
  /// owner types. Off for every product that never opts in.
  final bool isSerialized;

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
    this.isSerialized = false,
  });

  /// True when a low-stock alert is set and on-hand has reached it.
  bool get isLowStock => minStockAlert > 0 && quantity <= minStockAlert;

  /// True when on-hand has reached zero (Plan 011 #8). Deliberately *not* gated
  /// on [minStockAlert]: the shop wants to see whether any product's quantity is
  /// zero, tracked or not, so a finished item is always flagged.
  bool get isOutOfStock => quantity <= 0;

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
    bool? isSerialized,
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
      isSerialized: isSerialized ?? this.isSerialized,
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
        isSerialized,
      ];
}
