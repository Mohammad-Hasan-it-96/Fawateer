// The quick stock-status filter on the products page (Plan 013 #1).
//
// Pure predicate, so a unit test. What matters is that the filter and the badge
// on the same row can never disagree about what "out of stock" means — both go
// through Product.isOutOfStock / isLowStock.
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/product_stock_filter.dart';
import 'package:flutter_test/flutter_test.dart';

Product _p({required double qty, double alert = 0}) => Product(
      id: 'p',
      name: 'Item',
      price: 1000,
      quantity: qty,
      minStockAlert: alert,
      barcode: '',
    );

void main() {
  test('"all" keeps everything', () {
    for (final p in [_p(qty: 0), _p(qty: 5), _p(qty: 2, alert: 5)]) {
      expect(ProductStockFilter.all.matches(p), isTrue);
    }
  });

  test('out of stock is quantity <= 0, tracked or not', () {
    // Plan 011 #8 decided the shop wants zero flagged for every product, not
    // only the ones with a minimum set. The filter must not re-decide that.
    expect(ProductStockFilter.outOfStock.matches(_p(qty: 0)), isTrue);
    expect(ProductStockFilter.outOfStock.matches(_p(qty: 0, alert: 5)), isTrue);
    expect(ProductStockFilter.outOfStock.matches(_p(qty: 1)), isFalse);
  });

  test('low stock needs a minimum the owner actually set', () {
    // Without a threshold there is no such thing as "low" — most of a loose
    // goods catalogue would otherwise be reported as running out.
    expect(ProductStockFilter.lowStock.matches(_p(qty: 2, alert: 5)), isTrue);
    expect(ProductStockFilter.lowStock.matches(_p(qty: 2)), isFalse);
    expect(ProductStockFilter.lowStock.matches(_p(qty: 9, alert: 5)), isFalse);
  });

  test('low stock excludes what has already run out', () {
    // A shopkeeper filtering for "running low" is looking for what to reorder
    // BEFORE it goes; the empty ones have their own chip, and listing them in
    // both makes the low-stock list mostly zeroes.
    expect(ProductStockFilter.lowStock.matches(_p(qty: 0, alert: 5)), isFalse);
    expect(ProductStockFilter.outOfStock.matches(_p(qty: 0, alert: 5)), isTrue);
  });

  test('at exactly the threshold counts as low', () {
    // "Warn me when it reaches 5" means at 5, not at 4.
    expect(ProductStockFilter.lowStock.matches(_p(qty: 5, alert: 5)), isTrue);
  });
}
