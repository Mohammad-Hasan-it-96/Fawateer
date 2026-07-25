import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

import '../../../../core/utils/barcode_formats.dart';
import '../../../../l10n/app_localizations.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    // `normal` (not `noDuplicates`) so the same value re-fires across frames —
    // required for the multi-frame confirmation below (Plan 011 #11).
    detectionSpeed: DetectionSpeed.normal,
    returnImage: false,
    // Retail/wholesale symbologies only — fewer wrong reads (Plan 011 #11).
    formats: kRetailBarcodeFormats,
    // No pinned cameraResolution — forcing a fixed size fails to start on
    // devices that don't support it (the "camera unavailable" latch).
  );
  bool _isScanned = false;

  // Multi-frame confirmation: a value must decode identically on this many
  // consecutive frames before we accept it, so a one-off misread off a
  // curved/glary surface is rejected. See the note in home_page's scanner.
  String? _pendingScan;
  int _pendingScanCount = 0;
  static const int _kScanConfirmations = 2;

  /// Camera zoom (0…1), driven by pinch / double-tap (Plan 011 #9).
  double _zoom = 0;
  double _zoomStart = 0;

  void _applyZoom(double z) {
    final clamped = z.clamp(0.0, 1.0);
    if (clamped == _zoom) return;
    setState(() => _zoom = clamped);
    controller.setZoomScale(clamped).catchError((_) {});
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isScanned) return;
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null) {
        // Require the same value on consecutive frames before accepting it.
        if (rawValue == _pendingScan) {
          _pendingScanCount++;
        } else {
          _pendingScan = rawValue;
          _pendingScanCount = 1;
        }
        if (_pendingScanCount < _kScanConfirmations) break;

        _isScanned = true;
        // Vibrate
        final canVibrate = await Vibrate.canVibrate;
        if (canVibrate) {
          Vibrate.feedback(FeedbackType.success);
        }

        if (mounted) {
          context.pop(rawValue);
        }
        break; // Only take first one
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         leading: IconButton(
          icon: Icon(Icons.chevron_left,
              size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
        title: Text(AppLocalizations.of(context)!.scanBarcodeTitle,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18))),
      body: Stack(
        children: [
          // Pinch / double-tap to zoom (Plan 011 #9) — helps read a small or
          // awkward barcode; mobile_scanner has no manual tap-to-focus.
          GestureDetector(
            onScaleStart: (_) => _zoomStart = _zoom,
            onScaleUpdate: (details) {
              if (details.scale == 1.0) return;
              _applyZoom(_zoomStart + (details.scale - 1));
            },
            onDoubleTap: () => _applyZoom(_zoom > 0 ? 0 : 0.5),
            child: MobileScanner(
              controller: controller,
              onDetect: _onDetect,
            ),
          ),
          // Simple border overlay manually
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.transparent, width: 0),
            ),
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                  // borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _corner(0),
                          _corner(1),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _corner(3),
                          _corner(2),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              AppLocalizations.of(context)!.alignBarcodeHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner(int index) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}
