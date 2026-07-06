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
  String get customersTab => 'Customers';

  @override
  String get settingsTab => 'Settings';

  @override
  String get scannedItems => 'Scanned Items';

  @override
  String itemsCount(String count) {
    return '$count items total';
  }

  @override
  String get totalPrice => 'TOTAL PRICE';

  @override
  String get reviewOrder => 'Review Order';

  @override
  String get cameraUnavailable => 'Camera unavailable';

  @override
  String get cameraPermissionHint =>
      'Allow camera access to scan barcodes, or add items manually below.';

  @override
  String get openSettings => 'Open Settings';

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
  String get cartEmptyError => 'Add an item before confirming the sale.';

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
  String get historyLoadFailed => 'Couldn\'t load sales history.';

  @override
  String get itemsLoadFailed => 'Couldn\'t load items. Tap to retry.';

  @override
  String get shopLoadFailed => 'Couldn\'t load shop details.';

  @override
  String get shopSaveFailed => 'Couldn\'t save. Please try again.';

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
  String stockCountLabel(String qty) {
    return 'In stock: $qty';
  }

  @override
  String get lowStockBadge => 'Low stock';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get quantityDialogTitle => 'Quantity';

  @override
  String get addProductTitle => 'Add Product';

  @override
  String get barcodeLabel => 'Barcode (optional)';

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
  String get lowStockAlertLabel => 'Low-stock alert (optional)';

  @override
  String get lowStockAlertHint =>
      'Warn when stock reaches this amount. 0 = off';

  @override
  String get productAdded => 'Product added';

  @override
  String get productUpdated => 'Product updated';

  @override
  String get productDeleted => 'Product deleted';

  @override
  String get errorSaveFailed => 'Couldn\'t save. Please try again.';

  @override
  String get errorLoadFailed => 'Couldn\'t load products.';

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
  String get priceMustBePositive => 'Price must be greater than zero';

  @override
  String get invalidNumber => 'Please enter a valid number';

  @override
  String get negativeNotAllowed => 'Cannot be negative';

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

  @override
  String get licenseChecking => 'Checking your subscription…';

  @override
  String get licenseErrorNetwork =>
      'No internet connection. Please check your network and try again.';

  @override
  String get licenseErrorServer =>
      'Couldn\'t verify your subscription right now. Please try again.';

  @override
  String get licenseErrorUnexpected =>
      'Something went wrong. Please try again.';

  @override
  String get activationTitle => 'Activate Fawateer';

  @override
  String get activationSubtitle =>
      'Enter your details to verify your subscription, or choose a plan to get started.';

  @override
  String get activationNameLabel => 'Full Name';

  @override
  String get activationPhoneLabel => 'Phone Number';

  @override
  String get activationCheckButton => 'Verify Activation';

  @override
  String get activationViewPlans => 'View Subscription Plans';

  @override
  String get licenseExpiredTitle => 'Subscription Expired';

  @override
  String get licenseExpiredSubtitle =>
      'Renew your subscription to keep using the app.';

  @override
  String licenseExpiresOn(String date) {
    return 'Valid until $date';
  }

  @override
  String get plansTitle => 'Subscription Plans';

  @override
  String get plansEmpty => 'No plans available right now.';

  @override
  String get retry => 'Retry';

  @override
  String get planRecommended => 'BEST VALUE';

  @override
  String planDurationMonths(int count) {
    return '$count month(s)';
  }

  @override
  String get planSubscribe => 'Subscribe';

  @override
  String get planRequestSent =>
      'Your request was sent. We\'ll activate your device shortly.';

  @override
  String get contactMethodTitle => 'Contact us to complete your subscription';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String contactMessage(String plan) {
    return 'Hello, I\'d like to subscribe to the $plan plan for Fawateer.';
  }

  @override
  String get customersTitle => 'Customers';

  @override
  String get addCustomer => 'Add Customer';

  @override
  String get editCustomer => 'Edit Customer';

  @override
  String get customerNameLabel => 'Name';

  @override
  String get customerPhoneLabel => 'Phone (optional)';

  @override
  String get customerNoteLabel => 'Note (optional)';

  @override
  String get customerAdded => 'Customer added';

  @override
  String get customerUpdated => 'Customer updated';

  @override
  String get customerDeleted => 'Customer deleted';

  @override
  String get customerDeleteBlocked =>
      'Can\'t delete a customer who has ledger entries.';

  @override
  String get customerSaveFailed => 'Couldn\'t save. Please try again.';

  @override
  String get customersLoadFailed => 'Couldn\'t load customers.';

  @override
  String get noCustomers => 'No customers yet';

  @override
  String get noCustomersHint =>
      'Add a customer to track credit sales and payments.';

  @override
  String get balanceSettled => 'Settled';

  @override
  String balanceOwed(String amount) {
    return 'Owes $amount';
  }

  @override
  String balanceCredit(String amount) {
    return 'Credit $amount';
  }

  @override
  String get balanceOwedLabel => 'Owes you';

  @override
  String get balanceCreditLabel => 'You owe';

  @override
  String get recordPayment => 'Record Payment';

  @override
  String get addDebt => 'Add Debt';

  @override
  String get noLedgerEntries => 'No transactions yet';

  @override
  String get entryPayment => 'Payment';

  @override
  String get entryDebt => 'Debt';

  @override
  String get creditSaleTag => 'Credit sale';

  @override
  String get deleteEntryTitle => 'Delete Entry';

  @override
  String get deleteEntryConfirm => 'Delete this ledger entry?';

  @override
  String get debtAdded => 'Debt added';

  @override
  String get paymentRecorded => 'Payment recorded';

  @override
  String get entryDeleted => 'Entry deleted';

  @override
  String get ledgerSaveFailed => 'Couldn\'t save. Please try again.';

  @override
  String get ledgerLoadFailed => 'Couldn\'t load the account.';

  @override
  String get amountLabel => 'Amount';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get amountMustBePositive => 'Enter an amount greater than zero';

  @override
  String get sellOnCredit => 'Sell on credit';

  @override
  String get cashSale => 'Cash';

  @override
  String get chooseCustomer => 'Choose customer';

  @override
  String creditToLabel(String name) {
    return 'Credit — $name';
  }

  @override
  String get shareStatement => 'Share statement';

  @override
  String get printStatement => 'Print statement';

  @override
  String get statementPrinted => 'Statement printed';

  @override
  String statementHeader(String shop) {
    return 'Account Statement — $shop';
  }

  @override
  String get statementDate => 'Date';

  @override
  String get statementTotalDebts => 'Total debts';

  @override
  String get statementTotalPaid => 'Total paid';

  @override
  String get statementBalance => 'Balance';

  @override
  String get accountSection => 'Account';

  @override
  String get subscriptionItem => 'Subscription';

  @override
  String get subscriptionSubtitle => 'View status & renew your plan';

  @override
  String get subscriptionTitle => 'Subscription';

  @override
  String get statusActive => 'Active';

  @override
  String get statusTrial => 'Trial';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusInactive => 'Not activated';

  @override
  String daysRemaining(int days) {
    return '$days days left';
  }

  @override
  String lastChecked(String date) {
    return 'Last checked: $date';
  }

  @override
  String get neverChecked => 'never';

  @override
  String get refreshStatus => 'Refresh status';

  @override
  String get renewSubscription => 'Renew / change plan';

  @override
  String get deviceIdLabel => 'Device ID';

  @override
  String get deviceIdHint => 'Send this ID to support to activate your device.';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get subscriptionActivatedBanner =>
      'Your subscription has been activated';
}
