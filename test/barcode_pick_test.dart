// Choosing between a barcode and a QR code decoded from the SAME frame
// (`docs/v1-fixes-2.txt` #6, Plan 013).
//
// The shop reported that a product carrying both a printed barcode and a QR
// label always scanned as the QR. The cause was that both scanners took
// `capture.barcodes.first` — an order ML Kit picks and the app never did. So the
// **order of the list in each fixture below is the point of the test**: put the
// QR first, exactly as the failing frames did, and the barcode must still win.
import 'package:billing_app/core/utils/barcode_formats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

Barcode _code(BarcodeFormat format, String? value) =>
    Barcode(format: format, rawValue: value);

void main() {
  test('a 1D barcode beats a QR listed before it', () {
    final picked = pickRetailBarcode([
      _code(BarcodeFormat.qrCode, 'https://example.com/promo'),
      _code(BarcodeFormat.ean13, '6221033000123'),
    ]);

    // The 1D code names the product; the QR on the same package is a marketing
    // link that means nothing to this shop.
    expect(picked?.rawValue, '6221033000123');
  });

  test('a QR alone is still returned', () {
    // Required, not incidental: the app prints its own product labels as QR
    // (`LabelImage`) and both scanners have to read them.
    final picked =
        pickRetailBarcode([_code(BarcodeFormat.qrCode, 'FW-PRODUCT-9')]);

    expect(picked?.rawValue, 'FW-PRODUCT-9');
  });

  test('every retail 1D symbology wins over a QR', () {
    // A wholesale carton prints ITF; the app's own thermal labels print
    // Code128; groceries print EAN/UPC. Missing one would leave that whole
    // class of product still scanning as the QR.
    for (final format in kLinearRetailFormats) {
      final picked = pickRetailBarcode([
        _code(BarcodeFormat.qrCode, 'qr'),
        _code(format, 'linear'),
      ]);
      expect(picked?.rawValue, 'linear', reason: '$format should win');
    }
  });

  test('the first 1D code wins when a frame decodes two of them', () {
    // Two products in view at once. Either answer is defensible; taking the
    // first is stable and matches the old behaviour for this case, so a
    // two-product frame behaves exactly as it did before this change.
    final picked = pickRetailBarcode([
      _code(BarcodeFormat.ean13, 'first'),
      _code(BarcodeFormat.code128, 'second'),
    ]);

    expect(picked?.rawValue, 'first');
  });

  test('entries with no value are skipped, not returned', () {
    // ML Kit can report a detection whose rawValue never resolved. Returning it
    // would have crashed the `rawValue!` at the call sites.
    final picked = pickRetailBarcode([
      _code(BarcodeFormat.ean13, null),
      _code(BarcodeFormat.ean13, ''),
      _code(BarcodeFormat.qrCode, 'usable'),
    ]);

    expect(picked?.rawValue, 'usable');
  });

  test('a frame that decoded nothing usable returns null', () {
    expect(pickRetailBarcode([]), isNull);
    expect(pickRetailBarcode([_code(BarcodeFormat.ean13, null)]), isNull);
  });

  test('an unknown format is a fallback, never preferred', () {
    // `unknown` is not treated as 1D. If ML Kit cannot name the symbology we
    // cannot claim it identifies the product, so a real 1D code outranks it.
    final picked = pickRetailBarcode([
      _code(BarcodeFormat.unknown, 'mystery'),
      _code(BarcodeFormat.ean13, '6221033000123'),
    ]);
    expect(picked?.rawValue, '6221033000123');

    // …but alone it is still better than nothing.
    expect(pickRetailBarcode([_code(BarcodeFormat.unknown, 'mystery')])
        ?.rawValue, 'mystery');
  });

  test('the linear set stays a subset of the scanned formats', () {
    // The scanner only decodes `kRetailBarcodeFormats`. A linear format listed
    // here but missing there can never arrive, which would make the preference
    // silently dead for that symbology.
    for (final format in kLinearRetailFormats) {
      expect(kRetailBarcodeFormats, contains(format),
          reason: '$format is preferred but never scanned');
    }
  });
}
