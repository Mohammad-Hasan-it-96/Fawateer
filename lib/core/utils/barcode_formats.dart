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
  BarcodeFormat.itf,
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.codabar,
  BarcodeFormat.qrCode,
];
