import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';

import 'label_image.dart';
import 'receipt_image.dart';

class PrinterHelper {
  // Singleton
  static final PrinterHelper _instance = PrinterHelper._internal();
  factory PrinterHelper() => _instance;
  PrinterHelper._internal();

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Bound every Bluetooth call so an off/out-of-range printer can't hang the
  /// UI indefinitely.
  static const Duration _btTimeout = Duration(seconds: 15);

  /// Ask the OS for the *live* connection state rather than trusting the cached
  /// [_isConnected] flag, which goes stale when the printer sleeps, powers off,
  /// or drifts out of range after a successful connect. Keeps [_isConnected] in
  /// sync with reality.
  Future<bool> isLiveConnected() async {
    try {
      final live = await PrintBluetoothThermal.connectionStatus
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      _isConnected = live;
      return live;
    } catch (_) {
      _isConnected = false;
      return false;
    }
  }

  Future<bool> checkPermission() async {
    // Request Bluetooth and Location permissions
    // Android 12+ needs BLUETOOTH_SCAN, BLUETOOTH_CONNECT
    // Older Android needs BLUETOOTH, BLUETOOTH_ADMIN, ACCESS_FINE_LOCATION

    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  Future<List<BluetoothInfo>> getBondedDevices() async {
    try {
      final List<BluetoothInfo> list =
          await PrintBluetoothThermal.pairedBluetooths;
      return list;
    } catch (e) {
      return [];
    }
  }

  Future<bool> connect(String macAddress) async {
    try {
      final bool result = await PrintBluetoothThermal.connect(
              macPrinterAddress: macAddress)
          .timeout(_btTimeout, onTimeout: () => false);
      _isConnected = result;
      return result;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      final bool result = await PrintBluetoothThermal.disconnect;
      _isConnected =
          !result; // If disconnected successfully, isConnected is false
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Print a plain line of text (used for the printer test print). Returns
  /// `true` only when the bytes were actually written.
  Future<bool> printText(String text) async {
    if (!await isLiveConnected()) return false;
    try {
      return await PrintBluetoothThermal.writeBytes(_textToBytes(text))
          .timeout(_btTimeout, onTimeout: () => false);
    } catch (_) {
      return false;
    }
  }

  /// Returns `true` only when the receipt bytes were actually written to the
  /// printer. A stale/dropped connection, a write failure, or a timeout returns
  /// `false` so callers never report a false "printed" success.
  ///
  /// The receipt is rendered to a bitmap and sent as an ESC/POS raster image so
  /// Arabic (RTL, shaped) prints correctly on any printer — see [ReceiptImage].
  Future<bool> printReceipt({
    required String shopName,
    required String address1,
    required String address2,
    required String phone,
    required List<Map<String, dynamic>> items, // Name, Qty, Price, Total
    required double total,
    required String footer,
    String currency = '',
  }) async {
    if (!await isLiveConnected()) return false;

    final bytes = await ReceiptImage.buildEscPosBytes(
      shopName: shopName,
      address1: address1,
      address2: address2,
      phone: phone,
      items: items,
      total: total,
      footer: footer,
      currency: currency,
    );

    try {
      return await PrintBluetoothThermal.writeBytes(bytes)
          .timeout(_btTimeout, onTimeout: () => false);
    } catch (_) {
      return false;
    }
  }

  /// Print [copies] of a product label (name, price, scannable code) as an
  /// ESC/POS raster image. Returns `true` only when the bytes were written.
  Future<bool> printLabel({
    required String name,
    required String priceText,
    String barcodeData = '',
    bool useQr = false,
    int copies = 1,
  }) async {
    if (!await isLiveConnected()) return false;
    try {
      final bytes = await LabelImage.buildEscPosBytes(
        name: name,
        priceText: priceText,
        barcodeData: barcodeData,
        useQr: useQr,
        copies: copies,
      );
      return await PrintBluetoothThermal.writeBytes(bytes)
          .timeout(_btTimeout, onTimeout: () => false);
    } catch (_) {
      return false;
    }
  }

  /// Print a multi-line text block (e.g. a customer account statement) as an
  /// ESC/POS raster image, so Arabic prints correctly. Returns `true` only when
  /// the bytes were actually written.
  Future<bool> printStatement(String text) async {
    if (!await isLiveConnected()) return false;
    try {
      final bytes = await ReceiptImage.buildTextEscPosBytes(text);
      return await PrintBluetoothThermal.writeBytes(bytes)
          .timeout(_btTimeout, onTimeout: () => false);
    } catch (_) {
      return false;
    }
  }

  /// Encode a plain ASCII line for the diagnostic test print only. Sales
  /// receipts go through [ReceiptImage] as a raster bitmap and print full
  /// Arabic; this Latin-1 path is just for the fixed-English "Test Print" line,
  /// so non-Latin code points are replaced with '?' to avoid stray control
  /// bytes.
  List<int> _textToBytes(String text) =>
      text.runes.map((r) => r <= 0xFF ? r : 0x3F).toList();
}
