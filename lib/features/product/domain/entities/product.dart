import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String
      id; // Using barcode as ID usually, but keeping separate ID is safer
  final String name;
  final String barcode;
  final double price;
  final double cost; // purchase cost, for margin/profit reporting
  final double quantity; // on-hand inventory (was stock); supports weight/fractions
  final double minStockAlert; // low-stock threshold; 0 = no alert

  const Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    this.cost = 0,
    this.quantity = 0,
    this.minStockAlert = 0,
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
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      quantity: quantity ?? this.quantity,
      minStockAlert: minStockAlert ?? this.minStockAlert,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, barcode, price, cost, quantity, minStockAlert];
}
