import 'package:billing_app/core/attributes/product_attributes.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/product_search.dart';
import 'package:flutter_test/flutter_test.dart';

Product _p({
  String id = 'p1',
  String name = 'Phone',
  String barcode = '123',
  Map<String, String> attrs = const {},
}) =>
    Product(
      id: id,
      name: name,
      barcode: barcode,
      price: 10,
      attributes: ProductAttributes(attrs),
    );

void main() {
  group('productMatchesSearch — free text', () {
    test('empty query and no filters match everything', () {
      expect(
          productMatchesSearch(_p(), query: '', attrFilters: const {}), true);
    });

    test('matches on name and barcode (lower-cased query)', () {
      final p = _p(name: 'iPhone 15', barcode: '99887');
      expect(productMatchesSearch(p, query: 'iphone', attrFilters: const {}),
          true);
      expect(
          productMatchesSearch(p, query: '998', attrFilters: const {}), true);
      expect(productMatchesSearch(p, query: 'samsung', attrFilters: const {}),
          false);
    });

    test('matches on a custom-field value — e.g. searching by IMEI', () {
      final p = _p(attrs: const {'imei': '356789104567890', 'color': 'أسود'});
      expect(
          productMatchesSearch(p,
              query: '356789104567890', attrFilters: const {}),
          true);
      expect(productMatchesSearch(p, query: 'أسود', attrFilters: const {}),
          true);
      expect(productMatchesSearch(p, query: 'nope', attrFilters: const {}),
          false);
    });
  });

  group('productMatchesSearch — choice-list filters', () {
    test('AND across fields, OR within a field', () {
      final black = _p(attrs: const {'color': 'أسود', 'size': 'L'});
      final white = _p(attrs: const {'color': 'أبيض', 'size': 'L'});

      // color ∈ {أسود} AND size ∈ {L}
      final filters = {
        'color': {'أسود'},
        'size': {'L'},
      };
      expect(productMatchesSearch(black, query: '', attrFilters: filters), true);
      expect(
          productMatchesSearch(white, query: '', attrFilters: filters), false);

      // OR within color: {أسود, أبيض} now lets white through too
      final orFilter = {
        'color': {'أسود', 'أبيض'},
      };
      expect(
          productMatchesSearch(white, query: '', attrFilters: orFilter), true);
    });

    test('a product missing the filtered field is excluded', () {
      final p = _p(attrs: const {'size': 'M'});
      expect(
          productMatchesSearch(p, query: '', attrFilters: {
            'color': {'أسود'}
          }),
          false);
    });

    test('an empty value set for a field is ignored (matches all)', () {
      final p = _p(attrs: const {'size': 'M'});
      expect(
          productMatchesSearch(p, query: '', attrFilters: {'color': <String>{}}),
          true);
    });

    test('text query and filters combine (both must hold)', () {
      final p = _p(name: 'Shirt', attrs: const {'color': 'أحمر'});
      final filter = {
        'color': {'أحمر'}
      };
      expect(
          productMatchesSearch(p, query: 'shirt', attrFilters: filter), true);
      expect(
          productMatchesSearch(p, query: 'pants', attrFilters: filter), false);
    });
  });
}
