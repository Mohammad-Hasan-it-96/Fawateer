import 'package:billing_app/features/billing/domain/entities/invoice_item.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plan 011 #10 — the unit (kg vs piece) shown on a stored invoice and on a
/// reprint.
///
/// Before the snapshot existed the unit was guessed from whether the quantity
/// was fractional, which quietly mislabels a whole-number weight sale. The
/// snapshot makes new sales exact; the guess survives *only* as a fallback for
/// rows written before the column existed, so old invoices are no worse than
/// they were.
InvoiceItem _item({required double quantity, String saleType = ''}) =>
    InvoiceItem(
      invoiceId: 'inv1',
      productId: 'p1',
      productName: 'Rice',
      price: 1000,
      quantity: quantity,
      saleType: saleType,
    );

void main() {
  group('snapshotted saleType (sales made since the migration)', () {
    test('a weighed line reads as measured even at a whole quantity', () {
      // The exact case the old heuristic got wrong: 2.000 kg is not "2 pieces".
      expect(_item(quantity: 2, saleType: 'weight').isMeasured, isTrue);
    });

    test('a fractional weighed line reads as measured', () {
      expect(_item(quantity: 0.333, saleType: 'weight').isMeasured, isTrue);
    });

    test('a piece line reads as pieces', () {
      expect(_item(quantity: 3, saleType: 'piece').isMeasured, isFalse);
    });

    test('an unknown stored value is not treated as weight', () {
      // Defensive: a value from a future sale type must not silently print kg.
      expect(_item(quantity: 1, saleType: 'volume').isMeasured, isFalse);
    });
  });

  group('legacy rows (saleType empty) fall back to the quantity guess', () {
    test('a fractional quantity is assumed to be a weighed sale', () {
      expect(_item(quantity: 0.5).isMeasured, isTrue);
    });

    test('a whole quantity is assumed to be pieces', () {
      expect(_item(quantity: 2).isMeasured, isFalse);
    });
  });

  test('default construction is a legacy/unknown line, not a piece claim', () {
    // The column defaults to '' rather than 'piece' on purpose: defaulting to
    // 'piece' would confidently mislabel every pre-migration weighed sale.
    expect(_item(quantity: 1).saleType, '');
  });
}
