// Bulk price/cost edit maths (Plan 015 B2.2).
//
// Pure, so a plain unit test. This is the part worth pinning: a wrong price is
// silent — the shop finds out at the end of the day, from the takings.
import 'package:billing_app/features/product/domain/bulk_price_edit.dart';
import 'package:billing_app/features/product/domain/entities/price_currency.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:flutter_test/flutter_test.dart';

Product _p({
  String id = 'p',
  double price = 1000,
  double cost = 600,
  PriceCurrency currency = PriceCurrency.sp,
}) =>
    Product(
      id: id,
      name: 'Item',
      barcode: '',
      price: price,
      cost: cost,
      priceCurrency: currency,
    );

void main() {
  group('set to an amount', () {
    test('every product gets exactly that price', () {
      const edit = BulkPriceEdit(
          field: BulkPriceField.price, mode: BulkPriceMode.setTo, value: 3000);
      expect(edit.newValueFor(_p(price: 1000)), 3000);
      expect(edit.newValueFor(_p(price: 9999)), 3000);
    });

    test('cost is a separate target and leaves the price alone', () {
      const edit = BulkPriceEdit(
          field: BulkPriceField.cost, mode: BulkPriceMode.setTo, value: 750);
      final out = edit.applyTo(_p(price: 1000, cost: 600));
      expect(out.cost, 750);
      expect(out.price, 1000);
    });
  });

  group('percentage', () {
    test('raises and lowers each product from its own number', () {
      const up = BulkPriceEdit(
          field: BulkPriceField.price, mode: BulkPriceMode.percent, value: 10);
      expect(up.newValueFor(_p(price: 1000)), 1100);
      expect(up.newValueFor(_p(price: 2500)), 2750);

      const down = BulkPriceEdit(
          field: BulkPriceField.price, mode: BulkPriceMode.percent, value: -20);
      expect(down.newValueFor(_p(price: 1000)), 800);
    });

    test('a percentage of nothing is still nothing', () {
      // A product with no cost recorded is not "raised" by 10% — there is
      // nothing to raise, and inventing one would fake a margin.
      const edit = BulkPriceEdit(
          field: BulkPriceField.cost, mode: BulkPriceMode.percent, value: 10);
      expect(edit.newValueFor(_p(cost: 0)), 0);
      expect(edit.changes(_p(cost: 0)), isFalse);
    });

    test('never goes below zero', () {
      // "Free" is a legal outcome; the shop paying the customer is not.
      const edit = BulkPriceEdit(
          field: BulkPriceField.price,
          mode: BulkPriceMode.percent,
          value: -300);
      expect(edit.newValueFor(_p(price: 1000)), 0);
    });

    test('a non-finite result leaves the price untouched', () {
      const edit = BulkPriceEdit(
          field: BulkPriceField.price,
          mode: BulkPriceMode.percent,
          value: double.infinity);
      expect(edit.newValueFor(_p(price: 1000)), 1000);
    });
  });

  group('rounding follows the currency', () {
    test('SP lands on a whole pound', () {
      // Piastres are dead — the same rule usdToSp follows. Without this a 7%
      // rise turns a 1000 price into 1070.0000000000002.
      const edit = BulkPriceEdit(
          field: BulkPriceField.price, mode: BulkPriceMode.percent, value: 7);
      expect(edit.newValueFor(_p(price: 1055)), 1129);
    });

    test('USD keeps two decimals', () {
      const edit = BulkPriceEdit(
          field: BulkPriceField.price, mode: BulkPriceMode.percent, value: 10);
      expect(
        edit.newValueFor(_p(price: 2.55, currency: PriceCurrency.usd)),
        2.81,
      );
    });
  });

  group('the preview count', () {
    test('only counts products the edit actually moves', () {
      const edit = BulkPriceEdit(
          field: BulkPriceField.price, mode: BulkPriceMode.setTo, value: 3000);
      final products = [
        _p(id: 'a', price: 1000),
        _p(id: 'b', price: 3000), // already there
        _p(id: 'c', price: 2000),
      ];
      expect(products.where(edit.changes).length, 2);
    });
  });

  group('mixed currencies', () {
    test('are detected', () {
      expect(mixesCurrencies([_p(), _p(currency: PriceCurrency.usd)]), isTrue);
      expect(mixesCurrencies([_p(), _p(id: 'b')]), isFalse);
      expect(mixesCurrencies(<Product>[]), isFalse);
    });

    test('a percentage still applies correctly across them', () {
      // This is why only "set to" is blocked: +10% means the same thing in
      // both currencies, and each product moves from its own base.
      const edit = BulkPriceEdit(
          field: BulkPriceField.price, mode: BulkPriceMode.percent, value: 10);
      expect(edit.newValueFor(_p(price: 1000)), 1100);
      expect(edit.newValueFor(_p(price: 10, currency: PriceCurrency.usd)), 11);
    });
  });
}
