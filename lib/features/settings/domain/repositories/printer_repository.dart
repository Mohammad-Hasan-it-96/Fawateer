import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/printer_device.dart';
import '../entities/receipt_line.dart';

abstract class PrinterRepository {
  Future<Either<Failure, List<PrinterDevice>>> scanDevices();
  Future<bool> connect(String macAddress);
  Future<bool> disconnect();
  Future<String?> getSavedPrinterMac();
  Future<String?> getSavedPrinterName();
  Future<void> savePrinterData(String mac, String name);
  Future<void> clearPrinterData();
  Future<void> testPrint(String shopName);

  /// Print a sales receipt. Ensures the printer is connected first — if it
  /// isn't, it tries to reconnect to the saved printer. Returns `true` only when
  /// the receipt bytes were actually written; `false` when no printer was
  /// available or the write failed/timed out.
  Future<bool> printReceipt({
    required String shopName,
    required String address1,
    required String address2,
    required String phone,
    required String footer,
    required double total,
    required List<ReceiptLine> items,
    String currency = '',
  });

  /// Print a plain-text block (e.g. a customer account statement) as a raster
  /// image so Arabic prints correctly. Ensures/reconnects the printer like
  /// [printReceipt]; returns `true` only when the bytes were actually written.
  Future<bool> printStatement(String text);

  /// Print [copies] of a product label (name, price, and a scannable code of
  /// [barcodeData]). [useQr] switches the code from a 1D barcode to QR; an empty
  /// [barcodeData] prints a name/price tag with no code. Ensures/reconnects the
  /// printer like [printReceipt]; returns `true` only when the bytes were
  /// actually written.
  Future<bool> printLabel({
    required String name,
    required String priceText,
    String barcodeData,
    bool useQr,
    int copies,
  });
}
