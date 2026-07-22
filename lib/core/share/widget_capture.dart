import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Render a widget that is NOT in the visible tree to a PNG, by mounting it in
/// an off-screen [OverlayEntry], letting it lay out + paint one frame, then
/// capturing its [RepaintBoundary].
///
/// This is the standard "capture an off-screen widget" technique: the entry is
/// inserted into the app's existing [Overlay] (so it inherits `Directionality`,
/// `Localizations` and `Theme` from `MaterialApp` above it — RTL/Arabic render
/// correctly), positioned far off to the side so it never flashes on screen,
/// captured, then removed.
///
/// [logicalWidth] fixes the card width; height is intrinsic (the child sizes to
/// its content). [pixelRatio] oversamples for a crisp image in chat apps.
/// Returns null if the boundary couldn't be captured (caller shows a failure).
Future<Uint8List?> captureWidgetToPng(
  BuildContext context, {
  required Widget child,
  double logicalWidth = 380,
  double pixelRatio = 3.0,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final key = GlobalKey();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      // Off-screen but still laid out and painted by the overlay stack.
      left: -logicalWidth * 3,
      top: 0,
      child: RepaintBoundary(
        key: key,
        child: Material(
          type: MaterialType.transparency,
          child: SizedBox(width: logicalWidth, child: child),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  try {
    // Give the subtree a couple of frames to lay out and paint (fonts/images).
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;

    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    entry.remove();
  }
}
