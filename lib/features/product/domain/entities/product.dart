import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String
      id; // Using barcode as ID usually, but keeping separate ID is safer
  final String name;
  final String barcode;
  final double price;
  final double cost; // purchase cost, for margin/profit reporting
  final int stock; // Optional implementation detail

  const Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    this.cost = 0,
    this.stock = 0,
  });

  Product copyWith({
    String? id,
    String? name,
    String? barcode,
    double? price,
    double? cost,
    int? stock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
    );
  }

  @override
  List<Object?> get props => [id, name, barcode, price, cost, stock];
}
