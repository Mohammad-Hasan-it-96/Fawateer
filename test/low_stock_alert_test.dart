// When a low-stock alert should fire (Plan 013 #10).
//
// This is the whole feature's judgement in two pure functions, and the failure
// mode is not a crash — it is a shop being pestered on every scan until they
// switch alerts off and never turn them back on.
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/low_stock_alert.dart';
import 'package:flutter_test/flutter_test.dart';

Product _p(String id, {required double qty, required double alert}) => Product(
      id: id,
      name: id,
      barcode: '',
      price: 100,
      quantity: qty,
      minStockAlert: alert,
    );

void main() {
  group('lowStockIds', () {
    test('a product at or under its alert level counts', () {
      expect(lowStockIds([_p('a', qty: 3, alert: 5)]), {'a'});
      expect(lowStockIds([_p('a', qty: 5, alert: 5)]), {'a'});
    });

    test('a product above its level does not', () {
      expect(lowStockIds([_p('a', qty: 6, alert: 5)]), isEmpty);
    });

    test('a product with no alert level never counts, even at zero', () {
      // The threshold IS the opt-in. Loose produce sits at zero forever, and
      // alerting on it would bury the products the shop actually tracks.
      expect(lowStockIds([_p('a', qty: 0, alert: 0)]), isEmpty);
    });

    test('negative stock still counts as low', () {
      // Overselling is allowed, so a count can be driven to zero and the sale
      // still completes. Below the line is below the line.
      expect(lowStockIds([_p('a', qty: 0, alert: 2)]), {'a'});
    });
  });

  group('newlyLowIds', () {
    test('a product crossing the line is announced', () {
      expect(newlyLowIds([_p('a', qty: 2, alert: 5)], {}), {'a'});
    });

    test('an already-announced product is not announced again', () {
      // The real bug this prevents: the product stream re-emits after every
      // single sale, so without this the shop gets a notification per scan of
      // an item that is already low.
      expect(newlyLowIds([_p('a', qty: 2, alert: 5)], {'a'}), isEmpty);
    });

    test('selling more of an already-low product still says nothing', () {
      expect(newlyLowIds([_p('a', qty: 1, alert: 5)], {'a'}), isEmpty);
    });

    test('only the products that crossed are announced', () {
      final products = [
        _p('a', qty: 2, alert: 5), // already known
        _p('b', qty: 1, alert: 5), // just crossed
        _p('c', qty: 9, alert: 5), // fine
      ];

      expect(newlyLowIds(products, {'a'}), {'b'});
    });

    test('a restocked product can alert again later', () {
      // The reorder reminder has to work more than once. Restocking drops the
      // id from what gets remembered (the caller stores lowStockIds of the
      // latest list), so running down again is a fresh crossing.
      final restocked = [_p('a', qty: 20, alert: 5)];
      final remembered = lowStockIds(restocked);
      expect(remembered, isEmpty);

      expect(newlyLowIds([_p('a', qty: 4, alert: 5)], remembered), {'a'});
    });

    test('a deleted product simply stops being announced', () {
      // Its id lingers in the remembered set until the next write; nothing
      // should try to report a product that is no longer there.
      expect(newlyLowIds(const [], {'a', 'b'}), isEmpty);
    });

    test('an empty catalogue announces nothing', () {
      expect(newlyLowIds(const [], const {}), isEmpty);
    });
  });
}
