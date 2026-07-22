import 'dart:ui' as ui;

import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';

import 'receipt_image.dart';

/// Renders a printable **product label** (name, price, and a scannable code) to
/// ESC/POS raster bytes (Plan 010). Same pixels-not-text discipline as
/// [ReceiptImage] — Arabic is shaped by the OS and the code is drawn as bars —
/// so it prints on any thermal printer. The encoded code value is the product's
/// barcode, so a label printed here scans back through the app's own scanner.
class LabelImage {
  LabelImage._();

  /// 58 mm print head, matching [ReceiptImage.width].
  static const int _width = 384;
  static const double _pad = 12;
  static const _black = Color(0xFF000000);
  static const _white = Color(0xFFFFFFFF);

  /// Build the byte stream for [copies] identical labels: one printer init, then
  /// the rendered raster + a feed, repeated. [barcodeData] empty → a name/price
  /// tag with no code. [useQr] switches Code128 → QR.
  static Future<List<int>> buildEscPosBytes({
    required String name,
    required String priceText,
    String barcodeData = '',
    bool useQr = false,
    int copies = 1,
  }) async {
    final image = await _render(
      name: name,
      priceText: priceText,
      barcodeData: barcodeData,
      useQr: useQr,
    );
    final raster = await ReceiptImage.imageToRaster(image);
    image.dispose();

    final n = copies < 1 ? 1 : (copies > 99 ? 99 : copies);
    final out = <int>[0x1B, 0x40]; // ESC @ (init once)
    for (var i = 0; i < n; i++) {
      out.addAll(raster);
      out.addAll(const [0x0A, 0x0A, 0x0A]); // feed between/after labels
    }
    return out;
  }

  static Future<ui.Image> _render({
    required String name,
    required String priceText,
    required String barcodeData,
    required bool useQr,
  }) async {
    final recorder = ui.PictureRecorder();
    const maxHeight = 1200.0;
    final canvas = ui.Canvas(
        recorder, Rect.fromLTWH(0, 0, _width.toDouble(), maxHeight));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, _width.toDouble(), maxHeight),
        Paint()..color = _white);

    const contentWidth = _width - _pad * 2;
    double y = _pad;

    void centeredText(String text, double size, FontWeight weight) {
      if (text.trim().isEmpty) return;
      final tp = TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(
                color: _black, fontSize: size, fontWeight: weight, height: 1.2)),
        textDirection: ui.TextDirection.rtl,
        textAlign: TextAlign.center,
        maxLines: 2,
      )..layout(maxWidth: contentWidth);
      tp.paint(canvas, Offset(_pad + (contentWidth - tp.width) / 2, y));
      y += tp.height + 6;
    }

    centeredText(name, 26, FontWeight.bold);
    centeredText(priceText, 30, FontWeight.bold);

    if (barcodeData.isNotEmpty) {
      y += 4;
      if (useQr) {
        const dim = 170.0;
        _drawCode(canvas, Barcode.qrCode(), barcodeData,
            left: _pad + (contentWidth - dim) / 2, top: y, width: dim, height: dim);
        y += dim + 4;
      } else {
        const bw = contentWidth - 8;
        const bh = 76.0;
        _drawCode(canvas, Barcode.code128(), barcodeData,
            left: _pad + 4, top: y, width: bw, height: bh);
        y += bh + 4;
        // Human-readable digits under a 1D barcode.
        centeredText(barcodeData, 18, FontWeight.normal);
      }
    }
    y += _pad;

    final picture = recorder.endRecording();
    final image = await picture.toImage(_width, y.ceil());
    picture.dispose();
    return image;
  }

  /// Draw a barcode/QR by iterating its bar elements and filling black rects.
  /// Any encoding error (e.g. data too long for the symbology) is swallowed so a
  /// label still prints its name/price instead of throwing.
  static void _drawCode(
    ui.Canvas canvas,
    Barcode bc,
    String data, {
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    final paint = Paint()..color = _black;
    try {
      for (final e in bc.make(data, width: width, height: height, drawText: false)) {
        if (e is BarcodeBar && e.black) {
          canvas.drawRect(
              Rect.fromLTWH(left + e.left, top + e.top, e.width, e.height),
              paint);
        }
      }
    } catch (_) {
      // Leave the code area blank; name/price already drawn.
    }
  }
}
