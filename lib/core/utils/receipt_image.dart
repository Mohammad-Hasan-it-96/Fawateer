import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'format.dart';

/// Renders a sales receipt to a monochrome bitmap using Flutter's text engine
/// (which shapes Arabic and lays it out right-to-left correctly), then encodes
/// it as ESC/POS raster (`GS v 0`) bytes. This is why receipts print real Arabic
/// instead of `?`: the OS does the shaping and we ship pixels, so it works on any
/// ESC/POS printer regardless of its built-in code pages.
class ReceiptImage {
  ReceiptImage._();

  /// Dot width of the print head. 384 = the common 58 mm thermal printer.
  static const int width = 384;
  static const double _pad = 8;
  static const _black = Color(0xFF000000);

  /// Build the full byte stream (printer init + raster image + line feeds).
  static Future<List<int>> buildEscPosBytes({
    required String shopName,
    required String address1,
    required String address2,
    required String phone,
    required List<Map<String, dynamic>> items, // name, qty, price, total
    required double total,
    required String footer,
    required String currency,
    String localeName = 'ar',
  }) async {
    final image = await _render(
      shopName: shopName,
      address1: address1,
      address2: address2,
      phone: phone,
      items: items,
      total: total,
      footer: footer,
      currency: currency,
      localeName: localeName,
    );
    final raster = await _imageToRaster(image);
    image.dispose();

    return <int>[
      0x1B, 0x40, // ESC @  (init)
      ...raster,
      0x0A, 0x0A, 0x0A, // feed
    ];
  }

  /// Build ESC/POS bytes for an arbitrary multi-line text block (e.g. a customer
  /// account statement). Rendered as a raster bitmap — same reason receipts are:
  /// the OS shapes Arabic (RTL) and we ship pixels, so it prints real Arabic on
  /// any printer instead of `?`.
  static Future<List<int>> buildTextEscPosBytes(String text) async {
    final image = await _renderTextBlock(text);
    final raster = await _imageToRaster(image);
    image.dispose();
    return <int>[
      0x1B, 0x40, // ESC @  (init)
      ...raster,
      0x0A, 0x0A, 0x0A, // feed
    ];
  }

  static Future<ui.Image> _renderTextBlock(String text) async {
    final recorder = ui.PictureRecorder();
    const maxHeight = 6000.0;
    final fullRect = Rect.fromLTWH(0, 0, width.toDouble(), maxHeight);
    final canvas = ui.Canvas(recorder, fullRect);
    canvas.drawRect(fullRect, Paint()..color = const Color(0xFFFFFFFF));

    const double contentWidth = width - _pad * 2;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: _black, fontSize: 20, height: 1.4),
      ),
      textDirection: ui.TextDirection.rtl,
      textAlign: TextAlign.right,
    )..layout(maxWidth: contentWidth);
    tp.paint(canvas, const Offset(_pad, _pad));

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, (tp.height + _pad * 2).ceil());
    picture.dispose();
    return image;
  }

  static String _money(String currency, num v) =>
      '$currency${v.toStringAsFixed(2)}';

  static Future<ui.Image> _render({
    required String shopName,
    required String address1,
    required String address2,
    required String phone,
    required List<Map<String, dynamic>> items,
    required double total,
    required String footer,
    required String currency,
    required String localeName,
  }) async {
    final recorder = ui.PictureRecorder();
    // Draw onto a generously tall canvas; we crop to the real content height
    // (yields the final image height) when rasterizing.
    const maxHeight = 6000.0;
    final fullRect = Rect.fromLTWH(0, 0, width.toDouble(), maxHeight);
    final canvas = ui.Canvas(recorder, fullRect);
    canvas.drawRect(fullRect, Paint()..color = const Color(0xFFFFFFFF));

    const double contentWidth = width - _pad * 2;
    double y = _pad;

    TextPainter tp(String text, double size, FontWeight weight) => TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
                color: _black, fontSize: size, fontWeight: weight, height: 1.25),
          ),
          textDirection: ui.TextDirection.rtl,
          textAlign: TextAlign.center,
          maxLines: 4,
        )..layout(maxWidth: contentWidth);

    void centered(String text, double size, FontWeight weight) {
      if (text.trim().isEmpty) return;
      final p = tp(text, size, weight);
      p.paint(canvas, Offset(_pad + (contentWidth - p.width) / 2, y));
      y += p.height + 4;
    }

    void divider() {
      y += 2;
      canvas.drawLine(
          Offset(_pad, y),
          Offset(width - _pad, y),
          Paint()
            ..color = _black
            ..strokeWidth = 1.5);
      y += 6;
    }

    // A line item / total row: Arabic label on the right (RTL), amount on the
    // left — matching how amounts sit at the leading edge in an RTL layout.
    void row(String label, String amount, double size, FontWeight weight) {
      final amt = TextPainter(
        text: TextSpan(
            text: amount,
            style: TextStyle(color: _black, fontSize: size, fontWeight: weight)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      final lbl = TextPainter(
        text: TextSpan(
            text: label,
            style: TextStyle(color: _black, fontSize: size, fontWeight: weight)),
        textDirection: ui.TextDirection.rtl,
        maxLines: 2,
      )..layout(maxWidth: contentWidth - amt.width - 12);

      final rowH = amt.height > lbl.height ? amt.height : lbl.height;
      amt.paint(canvas, Offset(_pad, y));
      lbl.paint(canvas, Offset(width - _pad - lbl.width, y));
      y += rowH + 4;
    }

    // Header
    centered(shopName, 30, FontWeight.bold);
    centered(address1, 20, FontWeight.normal);
    centered(address2, 20, FontWeight.normal);
    centered(phone, 20, FontWeight.normal);
    centered(
        DateFormat.yMMMd(localeName).add_jm().format(DateTime.now()),
        18,
        FontWeight.normal);
    divider();

    // Items
    for (final item in items) {
      final qty = formatQty(item['qty'] as num);
      final name = item['name'].toString();
      row('$qty × $name', _money(currency, item['total'] as num), 22,
          FontWeight.normal);
    }
    divider();

    // Total
    row('الإجمالي', _money(currency, total), 28, FontWeight.bold);
    y += 6;

    // Footer
    centered(footer, 20, FontWeight.normal);
    y += 8;

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, y.ceil());
    picture.dispose();
    return image;
  }

  /// Convert the rendered image to ESC/POS `GS v 0` raster, split into vertical
  /// bands so a tall receipt never exceeds a printer's per-command buffer.
  static Future<List<int>> _imageToRaster(ui.Image image) async {
    final w = image.width;
    final h = image.height;
    final data =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return const [];
    final rgba = data.buffer.asUint8List();
    final bytesPerRow = (w + 7) >> 3;

    const bandRows = 128; // safe band height across cheap printers
    final out = <int>[];

    for (int y0 = 0; y0 < h; y0 += bandRows) {
      final rows = (y0 + bandRows <= h) ? bandRows : h - y0;
      out.addAll([
        0x1D, 0x76, 0x30, 0x00, // GS v 0, m=0
        bytesPerRow & 0xFF, (bytesPerRow >> 8) & 0xFF,
        rows & 0xFF, (rows >> 8) & 0xFF,
      ]);
      for (int yy = 0; yy < rows; yy++) {
        final srcY = y0 + yy;
        for (int xb = 0; xb < bytesPerRow; xb++) {
          int b = 0;
          for (int bit = 0; bit < 8; bit++) {
            final x = xb * 8 + bit;
            if (x < w) {
              final idx = (srcY * w + x) * 4;
              final lum = (rgba[idx] + rgba[idx + 1] + rgba[idx + 2]) / 3;
              final alpha = rgba[idx + 3];
              if (alpha > 128 && lum < 128) b |= (0x80 >> bit);
            }
          }
          out.add(b);
        }
      }
    }
    return out;
  }
}
