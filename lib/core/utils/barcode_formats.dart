import 'package:mobile_scanner/mobile_scanner.dart';

/// The barcode symbologies a retail/wholesale shop actually uses (Plan 011 #11).
///
/// Restricting the scanner to this set — instead of the plugin default of
/// "scan everything" — cuts **wrong** reads: the decoder no longer has to guess
/// among exotic 2D formats (DataMatrix / PDF417 / Aztec) that never appear on a
/// grocery or wholesale product, which is where a misread digit comes from.
///
/// Covers EAN/UPC (retail), **ITF** (interleaved 2-of-5 — the format printed on
/// wholesale cartons, a likely culprit for the "won't read" product), Code128 /
/// Code39 / Code93 / Codabar (labels, including the app's own printed labels),
/// and QR (the app's product-QR labels).
const List<BarcodeFormat> kRetailBarcodeFormats = [
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.itf14,
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.codabar,
  BarcodeFormat.qrCode,
];

/// The **1D** (linear) symbologies out of [kRetailBarcodeFormats] — the ones a
/// factory prints on a product to identify *the product*.
///
/// Listed explicitly rather than derived as "everything that is not 2D": a new
/// 2D format appearing in a future plugin release would otherwise be silently
/// treated as a product code, which is the exact bug this exists to prevent.
/// Anything not in this set — QR today, `unknown` included — is a fallback.
///
/// **Must stay a subset of [kRetailBarcodeFormats]**, which is the set the
/// scanner actually decodes: a format preferred here but never requested there
/// is a preference that can never fire. Pinned by `test/barcode_pick_test.dart`
/// (it caught exactly that on the first cut — two ITF variants that this app
/// does not scan). Widening what is *scanned* is a separate decision, and one
/// Plan 011 #11 deliberately made in the other direction.
const Set<BarcodeFormat> kLinearRetailFormats = {
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.itf14,
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.codabar,
};

/// Pick the one barcode to act on out of a single camera frame
/// (`BarcodeCapture.barcodes`), or null when the frame decoded nothing usable.
///
/// **This exists because a frame can decode more than one code at once**
/// (`docs/v1-fixes-2.txt` #6). Plenty of products carry a printed barcode *and*
/// a QR label on the same package, and both scanners used to take
/// `barcodes.first` — an order ML Kit chooses and we never did. In practice the
/// QR won almost every time, because a QR decodes from far more angles and
/// distances than a 1D code does, so the cashier scanned a packet and the app
/// looked up a marketing URL.
///
/// **A 1D retail code always wins.** It is the code that names the product; a
/// QR on the same package is nearly always a website, a promotion or a warranty
/// link, and means nothing to this shop.
///
/// **QR still works when it is alone**, which is required, not incidental: the
/// app prints its own product labels as QR (`LabelImage`), and those are scanned
/// by the same two screens.
///
/// Pure and frame-local — it does **not** replace the multi-frame confirmation
/// that guards against misreads. That still runs, on whatever this returns.
Barcode? pickRetailBarcode(List<Barcode> barcodes) {
  Barcode? fallback;
  for (final barcode in barcodes) {
    final value = barcode.rawValue;
    if (value == null || value.isEmpty) continue;
    if (kLinearRetailFormats.contains(barcode.format)) return barcode;
    fallback ??= barcode;
  }
  return fallback;
}
