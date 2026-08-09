// "Duplicate this product" and the uniqueness rules it shares with the add and
// edit forms (Plan 015 B2.1).
import 'package:billing_app/core/attributes/product_attributes.dart';
import 'package:billing_app/features/product/domain/entities/price_currency.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/entities/product_sale_type.dart';
import 'package:billing_app/features/product/domain/product_duplicate.dart';
import 'package:billing_app/features/product/domain/product_uniqueness.dart';
import 'package:flutter_test/flutter_test.dart';

Product _source() => Product(
      id: 'orange',
      name: 'عصير برتقال',
      barcode: '6221031492',
      price: 3000,
      cost: 2100,
      quantity: 42,
      minStockAlert: 6,
      saleType: ProductSaleType.weight,
      priceCurrency: PriceCurrency.usd,
      attributes: ProductAttributes(const {'category': 'مشروبات'}),
      isSerialized: true,
    );

void main() {
  group('duplicate', () {
    test('carries over everything that describes the kind of thing', () {
      final copy =
          duplicateProduct(_source(), id: 'apple', name: 'عصير تفاح');

      expect(copy.price, 3000);
      expect(copy.cost, 2100);
      expect(copy.minStockAlert, 6);
      expect(copy.saleType, ProductSaleType.weight);
      expect(copy.priceCurrency, PriceCurrency.usd);
      expect(copy.isSerialized, isTrue);
      // The category rides along in the attribute bag — that is most of the
      // point: a new flavour belongs on the same shelf.
      expect(copy.attributes['category'], 'مشروبات');
    });

    test('starts with no stock', () {
      // Stock is a count of things on a shelf, and the new flavour is not on
      // the shelf yet. Inheriting 42 would invent inventory the shop does not
      // have — and on a serialized SKU it would claim units that physically
      // belong to the original.
      expect(duplicateProduct(_source(), id: 'x', name: 'y').quantity, 0);
    });

    test('does not carry the barcode', () {
      // A barcode identifies one product. Copying it would trip the unique
      // index on every save.
      expect(duplicateProduct(_source(), id: 'x', name: 'y').barcode, '');
    });

    test('takes a new barcode when one is given, and trims both fields', () {
      final copy = duplicateProduct(_source(),
          id: 'x', name: '  عصير تفاح  ', barcode: ' 6221031493 ');
      expect(copy.name, 'عصير تفاح');
      expect(copy.barcode, '6221031493');
    });

    test('is a different product, not the same one renamed', () {
      final copy = duplicateProduct(_source(), id: 'apple', name: 'عصير تفاح');
      expect(copy.id, 'apple');
      expect(copy.id, isNot(_source().id));
    });
  });

  group('name uniqueness', () {
    final catalogue = [
      Product(id: 'a', name: 'Cola', barcode: '', price: 1),
      Product(id: 'b', name: 'عصير برتقال', barcode: '', price: 1),
    ];

    test('ignores case and surrounding spaces', () {
      // Two rows a cashier cannot tell apart are one product as far as the
      // counter is concerned.
      expect(productNameTaken(catalogue, '  cola '), isTrue);
      expect(productNameTaken(catalogue, 'COLA'), isTrue);
      expect(productNameTaken(catalogue, 'Cola Zero'), isFalse);
    });

    test('a product does not collide with itself when renamed', () {
      expect(productNameTaken(catalogue, 'Cola', excludingId: 'a'), isFalse);
      expect(productNameTaken(catalogue, 'Cola', excludingId: 'b'), isTrue);
    });

    test('an empty name is not "taken" — that is the required-field rule', () {
      expect(productNameTaken(catalogue, '   '), isFalse);
    });
  });

  group('barcode uniqueness', () {
    final catalogue = [
      Product(id: 'a', name: 'Cola', barcode: '6221031492', price: 1),
      Product(id: 'b', name: 'Loose apples', barcode: '', price: 1),
      Product(id: 'c', name: 'Bread', barcode: '', price: 1),
    ];

    test('a used barcode is refused', () {
      expect(productBarcodeTaken(catalogue, '6221031492'), isTrue);
      expect(productBarcodeTaken(catalogue, '  6221031492 '), isTrue);
      expect(productBarcodeTaken(catalogue, '6221031493'), isFalse);
    });

    test('blank is never taken, however many products have none', () {
      // Loose produce and bakery items legitimately have no barcode, and a shop
      // can have dozens — which is why the database index is partial rather
      // than a plain unique constraint.
      expect(productBarcodeTaken(catalogue, ''), isFalse);
      expect(productBarcodeTaken(catalogue, '   '), isFalse);
    });
  });
}
