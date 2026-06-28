// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get posTab => 'POS';

  @override
  String get historyTab => 'History';

  @override
  String get productsTab => 'Products';

  @override
  String get settingsTab => 'Settings';

  @override
  String get scannedItems => 'Scanned Items';

  @override
  String itemsCount(int count) {
    return '$count items total';
  }

  @override
  String get totalPrice => 'TOTAL PRICE';

  @override
  String get reviewOrder => 'Review Order';

  @override
  String get cameraOff => 'Camera is turned off';

  @override
  String get cameraOffHint =>
      'Turn on the camera to scan barcodes automatically.';

  @override
  String get turnOnCamera => 'Turn on Camera';

  @override
  String get cartEmpty => 'Cart is empty';

  @override
  String get cartEmptyHint => 'Scanned items will appear here.';

  @override
  String get flash => 'Flash';

  @override
  String get camera => 'Camera';

  @override
  String get addItem => 'Add Item';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get colProduct => 'Product';

  @override
  String get colPrice => 'Price';

  @override
  String get colTotal => 'Total';

  @override
  String get grandTotal => 'GRAND TOTAL';

  @override
  String get confirmSale => 'Confirm Sale';

  @override
  String get lowStockPrefix => 'Low stock: ';

  @override
  String get saleConfirmed => 'Sale Confirmed!';

  @override
  String get invoiceIdPrefix => 'ID: ...';

  @override
  String get printReceipt => 'Print Receipt';

  @override
  String get newSale => 'New Sale';

  @override
  String get shopNotLoaded => 'Shop details not loaded';

  @override
  String get salesHistory => 'Sales History';

  @override
  String get todaysSales => 'TODAY\'S SALES';

  @override
  String get invoicesLabel => 'invoices';

  @override
  String get noSalesYet => 'No sales yet';

  @override
  String get noSalesHint => 'Completed sales will appear here.';

  @override
  String get productsTitle => 'Products';

  @override
  String get searchHint => 'Search products…';

  @override
  String get tapToScan => 'Tap the icon to open camera scanner';

  @override
  String get noProductsFound => 'No products found. Add some!';

  @override
  String get noProductsMatch => 'No products match your search.';

  @override
  String get deleteProductTitle => 'Delete Product';

  @override
  String deleteProductConfirm(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get addProductTitle => 'Add Product';

  @override
  String get barcodeLabel => 'Barcode';

  @override
  String get scanOrEnterBarcode => 'Scan or enter barcode';

  @override
  String get productNameLabel => 'Product Name';

  @override
  String get productNameHint => 'e.g. Basmati Rice';

  @override
  String get priceLabel => 'Price';

  @override
  String get costLabel => 'Cost (optional)';

  @override
  String get costHint => 'Purchase cost, used for profit reports';

  @override
  String get stockLabel => 'Stock Quantity (optional)';

  @override
  String get stockHint => 'Leave 0 to disable stock tracking';

  @override
  String get addProductBtn => 'Add Product';

  @override
  String get barcodeExistsError =>
      'A product with this barcode already exists!';

  @override
  String get editProductTitle => 'Edit Product';

  @override
  String get barcodeDisplay => 'BARCODE';

  @override
  String get stockEditLabel => 'Stock Quantity';

  @override
  String get stockEditHint => 'Set to 0 to disable stock tracking';

  @override
  String get saveChangesBtn => 'Save Changes';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get managementSection => 'Management';

  @override
  String get shopDetailsItem => 'Shop Details';

  @override
  String get shopDetailsSubtitle => 'Edit business info & address';

  @override
  String get hardwareSection => 'Hardware';

  @override
  String get printDeviceItem => 'Print Device';

  @override
  String get printerConnected => 'Printer connected';

  @override
  String get noPrinterConnected => 'No printer connected';

  @override
  String get connectedBadge => 'CONNECTED';

  @override
  String get bluetoothHint =>
      'To connect: pair from phone Bluetooth settings, then tap Refresh.';

  @override
  String get shopDetailsTitle => 'Shop Details';

  @override
  String get generalInfo => 'General Information';

  @override
  String get receiptInfoNote => 'These details will appear on your receipts.';

  @override
  String get shopNameLabel => 'Shop Name';

  @override
  String get shopNameHint => 'e.g. QuickMart Superstore';

  @override
  String get address1Label => 'Address Line 1';

  @override
  String get address1Hint => 'Street / Area';

  @override
  String get address2Label => 'Address Line 2 (optional)';

  @override
  String get address2Hint => 'City, ZIP code';

  @override
  String get phoneLabel => 'Phone Number';

  @override
  String get phoneHint => '+1 555 000 0000';

  @override
  String get currencyLabel => 'Currency Symbol';

  @override
  String get currencyHint => '₹  \$  €  £';

  @override
  String get footerLabel => 'Receipt Footer (optional)';

  @override
  String get footerHint => 'Thank you, visit again!';

  @override
  String get footerMaxChars => 'Max 150 chars';

  @override
  String get saveDetailsBtn => 'Save Details';

  @override
  String get shopSaved => 'Shop details saved!';

  @override
  String get fieldRequired => 'Required';

  @override
  String get invalidPrice => 'Please enter a valid price';

  @override
  String get negativePriceError => 'Price cannot be negative';

  @override
  String get printedSuccessfully => 'Printed successfully';

  @override
  String get noItems => 'No items';

  @override
  String productNotFound(String barcode) {
    return 'Product not found: $barcode';
  }

  @override
  String get saleSaveFailed => 'Could not save the sale. Please try again.';

  @override
  String get printerUnavailable => 'No printer is connected.';

  @override
  String get printFailed => 'Printing failed. Please try again.';

  @override
  String get printerPermissionDenied => 'Bluetooth permission is required.';

  @override
  String get printerNoPairedDevices =>
      'No paired printer found. Pair one in Bluetooth settings.';

  @override
  String get printerConnectFailed => 'Could not connect to the printer.';

  @override
  String get printerScanFailed => 'Could not scan for printers.';
}
