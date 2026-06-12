import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../../../core/database/daos/settings_dao.dart';
import '../../../../core/utils/printer_helper.dart';
import '../../domain/repositories/printer_repository.dart';

class PrinterRepositoryDriftImpl implements PrinterRepository {
  final SettingsDao _settingsDao;
  final PrinterHelper _printerHelper = PrinterHelper();

  PrinterRepositoryDriftImpl(this._settingsDao);

  @override
  Future<List<BluetoothInfo>> scanDevices() async {
    if (await _printerHelper.checkPermission()) {
      return _printerHelper.getBondedDevices();
    }
    throw Exception('Bluetooth permission denied');
  }

  @override
  Future<bool> connect(String macAddress) => _printerHelper.connect(macAddress);

  @override
  Future<bool> disconnect() => _printerHelper.disconnect();

  @override
  Future<String?> getSavedPrinterMac() => _settingsDao.getValue('printer_mac');

  @override
  Future<String?> getSavedPrinterName() =>
      _settingsDao.getValue('printer_name');

  @override
  Future<void> savePrinterData(String mac, String name) async {
    await _settingsDao.setValue('printer_mac', mac);
    await _settingsDao.setValue('printer_name', name);
  }

  @override
  Future<void> clearPrinterData() async {
    await _settingsDao.deleteKey('printer_mac');
    await _settingsDao.deleteKey('printer_name');
  }

  @override
  Future<void> testPrint(String shopName) =>
      _printerHelper
          .printText('Test Print\n\n$shopName\n\n----------------\n\n');
}

