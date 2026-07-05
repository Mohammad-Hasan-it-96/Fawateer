import 'package:fpdart/fpdart.dart';
import '../../../../core/database/daos/settings_dao.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/printer_helper.dart';
import '../../domain/entities/printer_device.dart';
import '../../domain/entities/receipt_line.dart';
import '../../domain/repositories/printer_repository.dart';

class PrinterRepositoryDriftImpl implements PrinterRepository {
  final SettingsDao _settingsDao;
  final PrinterHelper _printerHelper = PrinterHelper();

  PrinterRepositoryDriftImpl(this._settingsDao);

  @override
  Future<Either<Failure, List<PrinterDevice>>> scanDevices() async {
    try {
      if (!await _printerHelper.checkPermission()) {
        return const Left(PermissionFailure('Bluetooth permission denied'));
      }
      final devices = await _printerHelper.getBondedDevices();
      return Right(devices
          .map((d) => PrinterDevice(name: d.name, mac: d.macAdress))
          .toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<bool> connect(String macAddress) => _printerHelper.connect(macAddress);

  @override
  Future<bool> disconnect() => _printerHelper.disconnect();

  // The methods below intentionally never throw: a DB/IO failure degrades
  // gracefully (null / no-op) instead of unwinding into a BLoC handler and
  // leaving its spinner stuck. Persistence is best-effort.

  @override
  Future<String?> getSavedPrinterMac() async {
    try {
      return await _settingsDao.getValue('printer_mac');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getSavedPrinterName() async {
    try {
      return await _settingsDao.getValue('printer_name');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePrinterData(String mac, String name) async {
    try {
      await _settingsDao.setValue('printer_mac', mac);
      await _settingsDao.setValue('printer_name', name);
    } catch (_) {
      // Best-effort: a failed save just means the printer isn't remembered.
    }
  }

  @override
  Future<void> clearPrinterData() async {
    try {
      await _settingsDao.deleteKey('printer_mac');
      await _settingsDao.deleteKey('printer_name');
    } catch (_) {
      // Best-effort.
    }
  }

  @override
  Future<void> testPrint(String shopName) async {
    try {
      if (!await _ensureConnected()) return;
      await _printerHelper
          .printText('Test Print\n\n$shopName\n\n----------------\n\n');
    } catch (_) {
      // Never let a diagnostic print throw into the BLoC.
    }
  }

  @override
  Future<bool> printReceipt({
    required String shopName,
    required String address1,
    required String address2,
    required String phone,
    required String footer,
    required double total,
    required List<ReceiptLine> items,
    String currency = '',
  }) async {
    if (!await _ensureConnected()) return false;

    // Propagate the real write result — a dropped connection or write failure
    // must surface as false, never a false "printed" success.
    return _printerHelper.printReceipt(
      shopName: shopName,
      address1: address1,
      address2: address2,
      phone: phone,
      footer: footer,
      total: total,
      currency: currency,
      items: items
          .map((i) => {
                'name': i.name,
                'qty': i.quantity,
                'price': i.price,
                'total': i.total,
              })
          .toList(),
    );
  }

  @override
  Future<bool> printStatement(String text) async {
    if (!await _ensureConnected()) return false;
    return _printerHelper.printStatement(text);
  }

  /// Make sure we have a *live* connection, reconnecting to the saved printer if
  /// the socket is dead. Returns false when there's nothing to connect to.
  Future<bool> _ensureConnected() async {
    if (await _printerHelper.isLiveConnected()) return true;
    final mac = await _settingsDao.getValue('printer_mac');
    if (mac == null) return false;
    return _printerHelper.connect(mac);
  }
}

