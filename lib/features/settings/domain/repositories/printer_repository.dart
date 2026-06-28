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
  /// isn't, it tries to reconnect to the saved printer. Returns `true` when the
  /// receipt was sent, `false` when no printer was available to print to.
  Future<bool> printReceipt({
    required String shopName,
    required String address1,
    required String address2,
    required String phone,
    required String footer,
    required double total,
    required List<ReceiptLine> items,
  });
}
