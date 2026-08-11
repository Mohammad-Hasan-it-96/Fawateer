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
  String get clearCart => 'Clear the invoice';

  @override
  String get clearCartTitle => 'Clear the whole invoice?';

  @override
  String get clearCartBody =>
      'All the scanned items will be removed. This cannot be undone.';

  @override
  String get clearCartConfirm => 'Clear';

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
  String get invertScanLabel => 'Light code';

  @override
  String get invertScanHint => 'Not scanning? Try light-barcode mode';

  @override
  String get pressBackAgainToExit => 'Press back again to exit';

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
  String get colSerial => 'No.';

  @override
  String get colQty => 'Qty';

  @override
  String get colUnit => 'Unit';

  @override
  String get colUnitPrice => 'Unit price';

  @override
  String get unitPiece => 'pc';

  @override
  String get grandTotal => 'GRAND TOTAL';

  @override
  String get confirmSale => 'Confirm Sale';

  @override
  String get lowStockPrefix => 'Low stock: ';

  @override
  String get outOfStockPrefix => 'Out of stock: ';

  @override
  String get insufficientStockError =>
      'Can\'t complete the sale — some items exceed available stock';

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
  String get filterYesterday => 'Yesterday';

  @override
  String get filterThisWeek => 'This Week';

  @override
  String get filterThisMonth => 'This Month';

  @override
  String get paymentCash => 'Cash';

  @override
  String get paymentCredit => 'Credit';

  @override
  String get paymentType => 'Payment';

  @override
  String get sortBy => 'Sort';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortOldest => 'Oldest';

  @override
  String get sortHighest => 'Highest amount';

  @override
  String get sortLowest => 'Lowest amount';

  @override
  String get summaryInvoices => 'Invoices';

  @override
  String get summaryTotal => 'Total';

  @override
  String get summaryCash => 'Cash';

  @override
  String get summaryCredit => 'Credit';

  @override
  String get summaryAverage => 'Average';

  @override
  String get searchInvoicesHint => 'Search invoice # or customer…';

  @override
  String get noSalesMatch => 'No sales match your filters.';

  @override
  String itemCountLabel(int count) {
    return '$count items';
  }

  @override
  String get invoiceDetails => 'Invoice Details';

  @override
  String get invoiceNumber => 'Invoice #';

  @override
  String get dateLabel => 'Date';

  @override
  String get timeLabel => 'Time';

  @override
  String get customerLabel => 'Customer';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get walkInCustomer => 'Walk-in customer';

  @override
  String get reprint => 'Reprint';

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
  String get showAll => 'Show all';

  @override
  String get noLowStockThresholds =>
      'No product has a minimum set yet. Open a product and set its low-stock alert to use this filter.';

  @override
  String get outOfStockBadge => 'Out of stock';

  @override
  String outOfStockScanNotice(String name) {
    return 'Out of stock: $name';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get quantityDialogTitle => 'Quantity';

  @override
  String get saleTypeLabel => 'Sale type';

  @override
  String get saleTypePiece => 'By piece';

  @override
  String get saleTypeWeight => 'By weight';

  @override
  String get pricePerKgLabel => 'Price per kg';

  @override
  String get unitKg => 'kg';

  @override
  String get weightFieldLabel => 'Weight (kg)';

  @override
  String get amountFieldLabel => 'Amount';

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
  String get inventorySection => 'Inventory';

  @override
  String get inventoryStrictTitle => 'Block selling out of stock';

  @override
  String get inventoryStrictSubtitle =>
      'Don\'t allow selling more than what\'s on hand';

  @override
  String get showPrintButtonTitle => 'Print receipts';

  @override
  String get showPrintButtonSubtitle =>
      'Show the print button and auto-print on a sale. Turn off if you have no printer.';

  @override
  String get shopDetailsItem => 'Shop Details';

  @override
  String get shopDetailsSubtitle => 'Edit business info & address';

  @override
  String get cashboxItem => 'Cashbox';

  @override
  String get cashboxSubtitle => 'Cash on hand, deposits & expenses';

  @override
  String get cashboxTitle => 'Cashbox';

  @override
  String get cashboxBalanceLabel => 'Current cash balance';

  @override
  String get todayCashIn => 'Today\'s cash in';

  @override
  String get todayCashOut => 'Today\'s cash out';

  @override
  String get addDeposit => 'Add deposit';

  @override
  String get withdrawMoney => 'Withdraw';

  @override
  String get addExpense => 'Add expense';

  @override
  String get viewHistory => 'History';

  @override
  String get addCashTransaction => 'Add transaction';

  @override
  String get selectType => 'Select type';

  @override
  String get recentTransactions => 'Recent activity';

  @override
  String get noCashTransactions => 'No cash transactions yet';

  @override
  String get cashHistoryTitle => 'Transaction history';

  @override
  String get cashInflow => 'In';

  @override
  String get cashOutflow => 'Out';

  @override
  String get filterAll => 'All';

  @override
  String get filterToday => 'Today';

  @override
  String get filterDateRange => 'Date range';

  @override
  String get filterByType => 'Type';

  @override
  String get cashDeleteTitle => 'Delete transaction?';

  @override
  String get cashDeleteConfirm =>
      'This cash transaction will be removed and the balance recalculated.';

  @override
  String get cashTransactionAdded => 'Transaction saved';

  @override
  String get cashTransactionDeleted => 'Transaction deleted';

  @override
  String get cashDeleteNotAllowed =>
      'Auto-created entries are removed by deleting their sale or payment';

  @override
  String get cashSaveFailed => 'Could not save the transaction';

  @override
  String get cashLoadFailed => 'Could not load the cashbox';

  @override
  String get cashTypeOpeningBalance => 'Opening balance';

  @override
  String get cashTypeCashSale => 'Cash sale';

  @override
  String get cashTypeCustomerDebtPayment => 'Debt payment';

  @override
  String get cashTypeManualDeposit => 'Deposit';

  @override
  String get cashTypeExpense => 'Expense';

  @override
  String get cashTypePersonalWithdrawal => 'Personal withdrawal';

  @override
  String get cashTypePurchasePayment => 'Purchase payment';

  @override
  String get cashTypeSupplierPayment => 'Supplier payment';

  @override
  String get cashTypeManualAdjustment => 'Adjustment';

  @override
  String get supportSection => 'Support & About';

  @override
  String get contactSupportItem => 'Contact support';

  @override
  String get contactSupportSubtitle => 'Get help with a problem or question';

  @override
  String get rateAppItem => 'Rate the app';

  @override
  String get rateAppSubtitle => 'Tell us how we are doing';

  @override
  String get rateAppThanksSubtitle => 'Thanks for your rating';

  @override
  String get shareAppItem => 'Share the app';

  @override
  String get shareAppSubtitle => 'Send it to another shop owner';

  @override
  String get shareAppMessage =>
      'Fawateer — a simple point-of-sale app for shops. Invoices, inventory, customer debts and reports, all offline.';

  @override
  String get appVersionItem => 'App version';

  @override
  String get aboutItem => 'About Fawateer';

  @override
  String get rateTitle => 'Rate Fawateer';

  @override
  String get ratePrompt => 'How is the app working for you?';

  @override
  String get rateCommentHint => 'Add a comment (optional)';

  @override
  String get rateSubmit => 'Send rating';

  @override
  String get rateThanks => 'Thank you! Your rating was sent.';

  @override
  String get rateFailed => 'Could not send your rating. Please try again.';

  @override
  String get supportSheetTitle => 'How would you like to reach us?';

  @override
  String get supportWhatsApp => 'WhatsApp';

  @override
  String get supportTelegram => 'Telegram';

  @override
  String get supportEmail => 'Email';

  @override
  String get supportEmailSubject => 'Fawateer support request';

  @override
  String get supportLaunchFailed =>
      'Could not open that app. Please try another way.';

  @override
  String get poweredBy => 'Developed by Evo Tech Systems';

  @override
  String get visitWebsite => 'evotech-sys.com';

  @override
  String get subscriptionActiveChip => 'Active';

  @override
  String get subscriptionInactiveChip => 'Inactive';

  @override
  String get trialChip => 'Trial';

  @override
  String get expiresOnLabel => 'Expires';

  @override
  String get planLabelShort => 'Plan';

  @override
  String get hardwareSection => 'Hardware';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get themeModeTitle => 'App theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'Follow system';

  @override
  String get fontSizeTitle => 'Font size';

  @override
  String get fontSizeTiny => 'Tiny';

  @override
  String get fontSizeSmall => 'Small';

  @override
  String get fontSizeNormal => 'Normal';

  @override
  String get fontSizeLarge => 'Large';

  @override
  String get fontSizeExtraLarge => 'Extra large';

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
  String get currencyHint => 'ل.س  \$  €  £';

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
  String unitsTitle(String product) {
    return 'Pieces — $product';
  }

  @override
  String unitsSummary(int available, int total) {
    return '$available of $total still in stock';
  }

  @override
  String get unitsAdd => 'Add item';

  @override
  String get unitsSerialLabel => 'Serial number';

  @override
  String get unitsSerialHint => 'Scan or type the number';

  @override
  String get unitsSearchHint => 'Search by serial number';

  @override
  String get unitsEmpty =>
      'No items yet.\nAdd one for each piece you have in stock.';

  @override
  String get unitsNoMatch => 'No item matches that number.';

  @override
  String get serialLabelShort => 'Serial';

  @override
  String get unitsNoSerial => '(no serial)';

  @override
  String get unitsSetWarranty => 'Set warranty date';

  @override
  String get unitsMarkDefective => 'Mark as defective';

  @override
  String get unitsRestock => 'Return to stock';

  @override
  String unitsWarrantyUntil(String date) {
    return 'Warranty until $date';
  }

  @override
  String unitsSoldOn(String date) {
    return 'Sold on $date';
  }

  @override
  String get unitStatusInStock => 'In stock';

  @override
  String get unitStatusSold => 'Sold';

  @override
  String get unitStatusReturned => 'Returned';

  @override
  String get unitStatusDefective => 'Defective';

  @override
  String get unitsAdded => 'Item added';

  @override
  String get unitsSaved => 'Saved';

  @override
  String get unitsDeleted => 'Item deleted';

  @override
  String get unitsLoadFailed => 'Could not load the list.';

  @override
  String get unitsSaveFailed => 'Could not save. Please try again.';

  @override
  String get unitsDuplicateSerial =>
      'This number is already registered. Check whether you scanned the same piece twice.';

  @override
  String get unitsDeleteBlockedSold =>
      'This piece has been sold and cannot be deleted — its record links the serial number to its invoice.';

  @override
  String get unitsDeleteTitle => 'Delete this piece?';

  @override
  String get unitsDeleteBody =>
      'It will be removed from stock. This cannot be undone.';

  @override
  String get productSerialized => 'Each piece has its own serial number';

  @override
  String get productSerializedHint =>
      'Turn on for goods tracked one by one — phones, appliances, tools, gold. Stock is then counted from the pieces you add.';

  @override
  String get productUnitsAction => 'Pieces';

  @override
  String get stockFromUnitsHint =>
      'Counted from the units you add — open Units to change it.';

  @override
  String unitNotAvailableError(String serial) {
    return 'This piece (serial $serial) is no longer in stock — it has already been sold.';
  }

  @override
  String get unknownBarcodeTitle => 'Barcode not registered';

  @override
  String unknownBarcodeMessage(String barcode) {
    return 'This barcode does not exist: $barcode\nDo you want to add it as a new product?';
  }

  @override
  String get unknownBarcodeAdd => 'Add new product';

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
  String get contactEmail => 'Email';

  @override
  String get contactEmailSubject => 'Fawateer subscription request';

  @override
  String get updateAvailableTitle => 'A new update is available';

  @override
  String get updateDownload => 'Download update';

  @override
  String get updateAvailableGeneric => 'A new version of the app is available.';

  @override
  String get updateLater => 'Later';

  @override
  String get verifyRequiredTitle => 'Subscription verification required';

  @override
  String get verifyOfflineMessage =>
      'The app hasn\'t been able to reach the server for a while. Please connect to the internet, then tap Retry to continue.';

  @override
  String get verifyTamperMessage =>
      'A change in the device\'s date and time was detected. Please correct the date and time, connect to the internet, then tap Retry.';

  @override
  String get verifyDataSafe => 'All your data is safe on this device.';

  @override
  String get verifyChecking => 'Checking…';

  @override
  String offlineWarnBanner(int days) {
    return 'No server connection for $days days — connect to the internet to verify';
  }

  @override
  String get trialExpiredNotice =>
      'Your free trial has ended. Choose a plan to activate a subscription and continue — all your data is safe.';

  @override
  String get subscriptionExpiredNotice =>
      'Your subscription has ended. Choose a plan to renew and continue — all your data is safe.';

  @override
  String get checkForUpdatesHint => 'Tap to check for updates';

  @override
  String get updateUpToDate => 'You\'re on the latest version';

  @override
  String get updateCheckFailed =>
      'Couldn\'t check for updates. Check your internet connection.';

  @override
  String contactMessage(
      String plan, String name, String phone, String deviceId) {
    return 'Hello,\nI\'d like to subscribe to Fawateer.\nPlan: $plan\nName: $name\nPhone: $phone\nDevice ID: $deviceId';
  }

  @override
  String get contactMessagePreview => 'The message we\'ll send';

  @override
  String get contactLaunchFailed =>
      'Couldn\'t open that app. Copy the message and send it to us manually.';

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
  String get searchCustomersHint => 'Search by name or phone';

  @override
  String get noCustomerResults => 'No customer matches this search';

  @override
  String get selectCustomer => 'Select customer';

  @override
  String get addNewCustomer => 'Add new customer';

  @override
  String get searchCustomerHint => 'Search customers';

  @override
  String get noMatchingCustomers => 'No matching customers';

  @override
  String get duplicateCustomerName =>
      'A customer with this name already exists';

  @override
  String andMoreTypeToSearch(int count) {
    return '+$count more — type to search';
  }

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
  String get deleteCustomerTitle => 'Delete Customer';

  @override
  String get deleteCustomerConfirm =>
      'Delete this customer? This can\'t be undone.';

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
  String get statementCardTitle => 'Account statement';

  @override
  String statementMoreEntries(int count) {
    return '…and $count earlier entries';
  }

  @override
  String get shareAsImage => 'Share as image';

  @override
  String get shareAsText => 'Share as text';

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
  String get accountInfoSection => 'Account details';

  @override
  String get notSet => 'Not set';

  @override
  String get editAccountTitle => 'Edit account details';

  @override
  String get agentSavedSynced => 'Saved and synced with the server';

  @override
  String get agentSavedLocal =>
      'Saved on this device — couldn\'t reach the server';

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

  @override
  String get trialBannerNoDate => 'Free trial';

  @override
  String trialBannerWithDate(int days, String date) {
    return 'Free trial — $days days left (until $date)';
  }

  @override
  String trialBanner(int days) {
    return 'Free trial — $days days left';
  }

  @override
  String get trialUpgrade => 'Upgrade';

  @override
  String get backupTitle => 'Backup & Restore';

  @override
  String get backupItem => 'Backup & Restore';

  @override
  String get backupSubtitle => 'Protect your data with Google Drive';

  @override
  String get backupSignInPrompt =>
      'Sign in with your Google account to keep a safe copy of all your data (sales, products, customers, debts, cash) in your own Google Drive. If your phone is lost or broken, you can restore everything on a new device.';

  @override
  String backupAccountHint(String account) {
    return 'Your previous backups are on the account $account';
  }

  @override
  String get backupSignInButton => 'Sign in with Google';

  @override
  String get backupSignOut => 'Sign out';

  @override
  String get backupAccountLabel => 'Signed-in account';

  @override
  String get backupNowButton => 'Back up now';

  @override
  String get backupAutoTitle => 'Automatic daily backup';

  @override
  String get backupAutoSubtitle =>
      'Backs up once a day when the app is opened and you are online.';

  @override
  String get backupExportButton => 'Export a copy to share';

  @override
  String get backupLastLabel => 'Last backup';

  @override
  String get backupNever => 'No backup yet — your data is not protected';

  @override
  String get backupListTitle => 'Your backups';

  @override
  String get backupListEmpty => 'No backups found in this account';

  @override
  String get backupRestore => 'Restore';

  @override
  String get backupThisDevice => 'This device';

  @override
  String get backupRestoreConfirmTitle => 'Restore this backup?';

  @override
  String get backupRestoreConfirmBody =>
      'This will replace ALL current data on this device with the selected backup. This cannot be undone. The app will close so you can reopen it fresh.';

  @override
  String get backupRestartTitle => 'Restore complete';

  @override
  String get backupRestartBody =>
      'Your data has been restored. Please reopen the app to finish.';

  @override
  String get backupRestartAction => 'Close app';

  @override
  String get backupRestoreFailedTitle => 'Restore did not finish';

  @override
  String get backupRestoreFailedBody =>
      'Your data has NOT been changed — it is safe exactly as it was. The app still needs to be reopened before it will work again.';

  @override
  String get backupSuccessBackedUp => 'Backup completed successfully';

  @override
  String get backupSuccessExported => 'Copy ready — choose where to share it';

  @override
  String get backupErrorNetwork =>
      'No internet connection. Connect and try again.';

  @override
  String get backupErrorServer => 'Google Drive error. Please try again.';

  @override
  String get backupErrorSignIn => 'Sign-in was cancelled or not completed.';

  @override
  String get backupErrorIncompatibleNew =>
      'This backup was made by a newer version of the app. Please update the app before restoring.';

  @override
  String get backupErrorCorrupt =>
      'This backup file is damaged and cannot be restored.';

  @override
  String get backupErrorUnknown => 'Something went wrong. Please try again.';

  @override
  String get backupBusyBackingUp => 'Backing up…';

  @override
  String get backupBusyRestoring => 'Restoring…';

  @override
  String get priceCurrencyLabel => 'Price currency';

  @override
  String get currencySp => 'SP';

  @override
  String get currencyUsd => 'USD';

  @override
  String get currencySettingsItem => 'Currency & Exchange Rate';

  @override
  String get currencySettingsSubtitle =>
      'Set the USD → SP rate for dollar-priced products';

  @override
  String get currencySettingsTitle => 'Currency & Exchange Rate';

  @override
  String get currencySettingsNote =>
      'Syrian Pound is your main currency. Products priced in US Dollars are converted to SP at this rate when you sell them. Changing the rate only affects new sales — past invoices keep their original rate.';

  @override
  String get exchangeRateLabel => 'SP per 1 USD';

  @override
  String get exchangeRateHint => 'e.g. 15000';

  @override
  String get exchangeRateInvalid => 'Enter a rate greater than zero';

  @override
  String get exchangeRateSaved => 'Exchange rate saved';

  @override
  String get exchangeRateNever => 'Not set yet';

  @override
  String get setExchangeRateShort => 'Set \$ rate';

  @override
  String exchangeRateUpdatedAt(String date) {
    return 'Last updated: $date';
  }

  @override
  String get exchangeRateMissingError =>
      'Set the USD exchange rate in Settings → Currency before selling a dollar-priced item.';

  @override
  String get discountTitle => 'Discount';

  @override
  String get discountPercent => 'Percent';

  @override
  String get discountAmount => 'Amount';

  @override
  String get discountValueHint => 'Value';

  @override
  String get discountApply => 'Apply';

  @override
  String get discountRemove => 'Remove';

  @override
  String get addDiscountAction => 'Discount';

  @override
  String get discountLabel => 'Discount';

  @override
  String get subtotalLabel => 'Subtotal';

  @override
  String get cartDiscountLabel => 'Cart discount';

  @override
  String get shareAction => 'Share';

  @override
  String get shareFailed => 'Couldn\'t prepare the share — please try again';

  @override
  String get estimatedProfit => 'Estimated profit';

  @override
  String get openingBalance => 'Opening balance';

  @override
  String get closingBalance => 'Closing balance';

  @override
  String get cashboxDailySummaryTitle => 'Daily cashbox summary';

  @override
  String get salesSummaryTitle => 'Sales summary';

  @override
  String get reportPeriodLabel => 'Period';

  @override
  String get receiptThankYou => 'Thank you for your business';

  @override
  String get reportsTab => 'Reports';

  @override
  String get dashboardTab => 'Dashboard';

  @override
  String get salesTabLabel => 'Sales';

  @override
  String get filterLast7Days => 'Last 7 days';

  @override
  String get filterLast30Days => 'Last 30 days';

  @override
  String get revenueLabel => 'Revenue';

  @override
  String get outstandingDebtsLabel => 'Outstanding debts';

  @override
  String get inventoryValueLabel => 'Inventory value';

  @override
  String get salesTrendTitle => 'Sales trend';

  @override
  String get topProductsTitle => 'Top products';

  @override
  String get cashFlowTitle => 'Cash flow';

  @override
  String get lowStockTitle => 'Low stock';

  @override
  String get stockConflictTitle => 'Sold more than you had';

  @override
  String get stockConflictBody =>
      'This usually happens when two phones sell the same item at the same time. Every sale was recorded — nothing was lost. Count these on the shelf and fix the amount.';

  @override
  String stockConflictShort(String qty) {
    return 'short $qty';
  }

  @override
  String get topDebtorsTitle => 'Top debtors';

  @override
  String get metricQuantity => 'Quantity';

  @override
  String get metricProfit => 'Profit';

  @override
  String get cashInLabel => 'Cash in';

  @override
  String get cashOutLabel => 'Cash out';

  @override
  String get expensesLabel => 'Expenses';

  @override
  String get withdrawalsLabel => 'Withdrawals';

  @override
  String get dashboardNoData => 'No sales in this period yet';

  @override
  String get dashboardLoadFailed => 'Couldn\'t load the dashboard';

  @override
  String unitsSuffix(String count) {
    return '$count sold';
  }

  @override
  String get scanBarcodeTitle => 'Scan Barcode';

  @override
  String get alignBarcodeHint => 'Align barcode within frame';

  @override
  String get productFieldsItem => 'Product fields';

  @override
  String get productFieldsSubtitle => 'Custom info stored per product';

  @override
  String get productFieldsTitle => 'Product fields';

  @override
  String get productFieldsEmpty => 'No custom fields yet';

  @override
  String get productFieldsEmptyHint =>
      'Add fields like Color or Storage, or start from a business template.';

  @override
  String get addFieldBtn => 'Add field';

  @override
  String get useTemplateBtn => 'Start from a template';

  @override
  String get chooseBusinessType => 'Choose your business type';

  @override
  String get templateSeedNote =>
      'Adds recommended fields. You can edit or remove them anytime.';

  @override
  String get fieldNameLabel => 'Field name';

  @override
  String get fieldNameHint => 'e.g. Color, Storage, Warranty';

  @override
  String get fieldTypeLabel => 'Field type';

  @override
  String get fieldUnitLabel => 'Unit (optional)';

  @override
  String get fieldUnitHint => 'e.g. GB, ml, V';

  @override
  String get fieldOptionsLabel => 'Choices';

  @override
  String get fieldOptionsHint => 'Separate choices with commas';

  @override
  String get fieldRequiredLabel => 'Required';

  @override
  String get fieldShowInListLabel => 'Show in product list';

  @override
  String get fieldShowOnReceiptLabel => 'Show on receipt';

  @override
  String get fieldArchiveAction => 'Archive';

  @override
  String get fieldUnarchiveAction => 'Restore';

  @override
  String get fieldDeleteAction => 'Delete';

  @override
  String get fieldArchivedBadge => 'Archived';

  @override
  String get attrTypeText => 'Text';

  @override
  String get attrTypeNumber => 'Number';

  @override
  String get attrTypeSelect => 'Choice list';

  @override
  String get attrTypeBoolean => 'Yes / No';

  @override
  String get attrTypeDate => 'Date';

  @override
  String get templateAppliedMsg => 'Fields added';

  @override
  String get showArchivedFields => 'Show archived';

  @override
  String get filterProductsTitle => 'Filter products';

  @override
  String get clearFiltersBtn => 'Clear all';

  @override
  String get noFilterableFields =>
      'No filterable fields. Add a choice-list field to filter by it.';

  @override
  String get salesByFieldTitle => 'Sales by field';

  @override
  String get salesByFieldHint =>
      'Pick a field to break sales down by its values.';

  @override
  String get reportFieldNone => 'Off';

  @override
  String get printLabelTitle => 'Print label';

  @override
  String get printLabelAction => 'Print';

  @override
  String get labelCopies => 'Copies';

  @override
  String get labelBarcode => 'Barcode';

  @override
  String get labelQr => 'QR';

  @override
  String get labelPrinted => 'Label sent to the printer';

  @override
  String get labelPrintFailed =>
      'Couldn\'t print — check the printer connection';

  @override
  String get unknownBarcodeSearch => 'Search';

  @override
  String get productNameExistsError =>
      'A product with this name already exists';

  @override
  String get syncItem => 'Devices & sync';

  @override
  String get syncSubtitle => 'Share this shop between two phones';

  @override
  String get syncTitle => 'Devices & sync';

  @override
  String get syncPitchTitle => 'Use this shop on more than one phone';

  @override
  String get syncPitchBody =>
      'Sales, products, customers and the cash drawer stay the same on every phone. Each phone keeps working with no internet and catches up when it reconnects.';

  @override
  String get syncEnableAction => 'Turn on for this shop';

  @override
  String get syncEnableHint =>
      'Choose this on the phone that already has your data.';

  @override
  String get syncJoinAction => 'Join a shop';

  @override
  String get syncJoinHint =>
      'Choose this on the second phone, then scan the code shown on the first.';

  @override
  String get syncStatusOwner => 'Main phone';

  @override
  String get syncStatusMember => 'Linked phone';

  @override
  String syncDevicesUsed(int used, int allowance) {
    return '$used of $allowance phones used';
  }

  @override
  String syncDevicesAllowed(int allowance) {
    return 'Phones allowed: $allowance';
  }

  @override
  String syncDevicesCount(int count) {
    return '$count phones';
  }

  @override
  String get syncStatusOwnerHint =>
      'Holds the subscription and can add or remove phones';

  @override
  String get syncStatusMemberHint => 'Shares this shop with the main phone';

  @override
  String syncAtCapHint(int allowance) {
    return 'All $allowance phones on your plan are in use. Remove one below to add another.';
  }

  @override
  String syncLastAt(String when) {
    return 'Last sync: $when';
  }

  @override
  String get syncNever => 'Not synced yet';

  @override
  String get syncNowAction => 'Sync now';

  @override
  String get syncUpToDate => 'Everything is up to date';

  @override
  String syncMovedCounts(int sent, int received) {
    return 'Sent $sent, received $received';
  }

  @override
  String syncPendingRejected(int count) {
    return '$count changes could not be sent — they will be retried';
  }

  @override
  String syncConflicts(int count) {
    return '$count changes were also edited on another phone — the newest one is kept';
  }

  @override
  String get syncAddDeviceAction => 'Add a phone';

  @override
  String get syncJoinCodeTitle => 'Scan on the other phone';

  @override
  String syncJoinCodeExpires(int minutes) {
    return 'Valid for $minutes more minutes';
  }

  @override
  String get syncJoinCodeExpired => 'This code has expired — create a new one';

  @override
  String get syncJoinCodeManual => 'Or type this code';

  @override
  String get syncJoinCodeCopied => 'Code copied';

  @override
  String get syncJoinCodeDone => 'Done';

  @override
  String get syncEnterCodeTitle => 'Join a shop';

  @override
  String get syncEnterCodeLabel => 'Code from the other phone';

  @override
  String get syncEnterCodeScan => 'Scan';

  @override
  String get syncEnterCodeConfirm => 'Join';

  @override
  String get syncLeaveAction => 'Unlink this phone';

  @override
  String get syncLeaveTitle => 'Unlink this phone?';

  @override
  String get syncLeaveBody =>
      'This phone keeps all its data but stops sharing with the others. Nothing is deleted.';

  @override
  String get syncLeaveConfirm => 'Unlink';

  @override
  String get syncEnabledMessage => 'Sync is on for this shop';

  @override
  String get syncJoinedMessage => 'This phone is linked';

  @override
  String get syncLeftMessage => 'This phone is no longer linked';

  @override
  String get syncErrorSubscription =>
      'Your subscription doesn\'t include extra phones';

  @override
  String get syncErrorAllowance =>
      'You\'ve used all the phones your plan allows';

  @override
  String get syncErrorJoinToken => 'That code is wrong, used, or expired';

  @override
  String get syncErrorFallbackDevice =>
      'This phone can\'t be identified reliably, so it can\'t be linked';

  @override
  String get syncErrorOffline => 'No connection — it will try again on its own';

  @override
  String get syncErrorServer => 'Something went wrong. Please try again';

  @override
  String get syncCopyCode => 'Copy';

  @override
  String get syncStepSyncing => 'Catching up with the other phones…';

  @override
  String get syncStepSnapshotting => 'Preparing a copy of the shop…';

  @override
  String get syncStepUploading => 'Sending the shop to the new phone…';

  @override
  String get syncJoinCodePreferScan =>
      'Scanning is safer than typing this code.';

  @override
  String get syncRestartTitle => 'The shop is on this phone';

  @override
  String get syncRestartBody =>
      'This phone now has a copy of the shop and needs to be opened again to use it. Close the app and start it again.';

  @override
  String get syncRestartConfirm => 'Close the app';

  @override
  String get syncDevicesTitle => 'Phones using this shop';

  @override
  String get syncDevicesRetry => 'Try again';

  @override
  String get syncDevicesUnavailable =>
      'Can\'t show the list of phones right now';

  @override
  String get syncDeviceThis => 'This phone';

  @override
  String get syncDeviceOwnerNote => 'Can\'t be removed';

  @override
  String get syncDeviceSeenNever => 'Not seen yet';

  @override
  String get syncDeviceSeenJustNow => 'Active now';

  @override
  String syncDeviceSeenMinutes(int minutes) {
    return 'Last used $minutes minutes ago';
  }

  @override
  String syncDeviceSeenHours(int hours) {
    return 'Last used $hours hours ago';
  }

  @override
  String syncDeviceSeenDays(int days) {
    return 'Last used $days days ago';
  }

  @override
  String get syncRevokeAction => 'Remove';

  @override
  String get syncRevokeTitle => 'Remove this phone?';

  @override
  String get syncRevokeBody =>
      'That phone will stop sharing this shop and will stop selling once it next checks its subscription. It keeps the copy of the shop it already has — this does not erase anything on it.';

  @override
  String get syncRevokeConfirm => 'Remove';

  @override
  String get syncRevokedMessage => 'That phone was removed';

  @override
  String get syncErrorRevoked =>
      'This phone was removed from the shop by the main phone';

  @override
  String get syncErrorOwnerOnly => 'Only the main phone can do this';

  @override
  String get selectAction => 'Select';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get selectAllAction => 'Select all';

  @override
  String get clearSelectionAction => 'Clear';

  @override
  String selectionHiddenByFilter(int count) {
    return '$count of them are hidden by the current filter';
  }

  @override
  String get bulkEditPricesAction => 'Edit prices';

  @override
  String bulkPriceTitle(int count) {
    return 'Change price for $count products';
  }

  @override
  String get bulkFieldPrice => 'Selling price';

  @override
  String get bulkFieldCost => 'Purchase cost';

  @override
  String get bulkModeSetTo => 'Set amount';

  @override
  String get bulkModePercent => 'Percentage';

  @override
  String get bulkPercentIncrease => 'Increase';

  @override
  String get bulkPercentDecrease => 'Decrease';

  @override
  String get bulkAmountLabel => 'New amount';

  @override
  String get bulkPercentLabel => 'Percentage %';

  @override
  String bulkPreviewCount(int count) {
    return '$count products will change';
  }

  @override
  String get bulkPreviewNoChange => 'Nothing will change with these numbers';

  @override
  String get bulkMixedCurrency =>
      'The selection has products priced in different currencies. Use a percentage, or select products of one currency only.';

  @override
  String get bulkApplyAction => 'Apply';

  @override
  String bulkPricesUpdated(int count) {
    return '$count products updated';
  }

  @override
  String get bulkPricesUnchanged => 'No price changed';

  @override
  String get tabAllProducts => 'All';

  @override
  String get tabByCategory => 'By category';

  @override
  String get categoryUncategorized => 'Other';

  @override
  String get categoryAllChip => 'All';

  @override
  String get noCategoriesTitle => 'No categories yet';

  @override
  String get noCategoriesHint =>
      'Create a few sections for your shop — drinks, dairy, cleaning. You can change them later from Settings → Product fields.';

  @override
  String get createCategoriesBtn => 'Create categories';

  @override
  String get categoriesDialogTitle => 'Shop categories';

  @override
  String get categoriesDialogHint => 'Category names, separated by a comma';

  @override
  String get manageCategoriesTooltip => 'Manage categories';

  @override
  String get setCategoryAction => 'Set category';

  @override
  String chooseCategoryTitle(int count) {
    return 'Category for $count products';
  }

  @override
  String get newCategoryHint => 'New category';

  @override
  String get categoryClearOption => 'No category';

  @override
  String bulkCategorySet(int count) {
    return '$count products moved';
  }

  @override
  String optionRenameTitle(String value) {
    return 'Rename \"$value\"';
  }

  @override
  String optionRenameMergeWarning(String value) {
    return '\"$value\" already exists — the two will be merged into one.';
  }

  @override
  String get optionRenameAction => 'Rename';

  @override
  String optionRemoveTitle(String value) {
    return 'Delete \"$value\"?';
  }

  @override
  String optionRemoveBody(int count) {
    return '$count products use it. They will keep everything else and simply have no value for this field.';
  }

  @override
  String optionInUseCount(int count) {
    return 'Used by $count products';
  }

  @override
  String optionRenamedMsg(int count) {
    return 'Renamed — $count products moved with it';
  }

  @override
  String optionRemovedMsg(int count) {
    return 'Deleted — $count products cleared';
  }

  @override
  String get addOptionHint => 'Add an option';

  @override
  String get optionsSectionTitle => 'Options';

  @override
  String get optionsLiveNote =>
      'Changes to the options are saved right away, and your products move with them.';

  @override
  String get duplicateProductAction => 'Duplicate';

  @override
  String duplicateProductTitle(String name) {
    return 'Duplicate \"$name\"';
  }

  @override
  String get duplicateProductHint =>
      'Price, cost, category and the other fields are copied. Stock starts at zero.';

  @override
  String get newProductNameLabel => 'New product name';

  @override
  String get newBarcodeLabel => 'Barcode (optional)';

  @override
  String get deleteInvoiceAction => 'Delete sale';

  @override
  String get deleteInvoiceTitle => 'Delete this sale?';

  @override
  String get deleteInvoiceIntro =>
      'This does not only remove the paper. It undoes the whole sale:';

  @override
  String get deleteInvoiceStock => 'The items go back into stock';

  @override
  String get deleteInvoiceCash => 'The cash comes out of the drawer';

  @override
  String deleteInvoiceDebt(String name) {
    return '$name\'s debt goes down by this amount';
  }

  @override
  String get deleteInvoiceIrreversible =>
      'This cannot be undone. Ring the sale again to correct it.';

  @override
  String get invoiceDeleted => 'Sale deleted';

  @override
  String get invoiceDeleteFailed => 'Couldn\'t delete the sale';

  @override
  String get changePaymentAction => 'Change payment';

  @override
  String get changePaymentTitle => 'How was this sale paid?';

  @override
  String get changePaymentIntro =>
      'Only the payment record changes. The items, the total and the receipt stay exactly as they are.';

  @override
  String get changePaymentCashHint => 'The amount goes into the cash drawer';

  @override
  String get changePaymentCreditHint =>
      'The amount is added to a customer\'s debt';

  @override
  String get changePaymentChooseCustomer => 'Choose customer';

  @override
  String get changePaymentNotRepayment =>
      'Use this to fix a mistake. If the customer is paying off a debt, record a payment on their account instead.';

  @override
  String get paymentChanged => 'Payment updated';

  @override
  String get paymentChangeFailed => 'Couldn\'t update the payment';

  @override
  String get managerLockSection => 'Manager lock';

  @override
  String get managerPinTitle => 'Manager PIN';

  @override
  String get managerPinOffSubtitle =>
      'Off — anyone can delete or change a sale';

  @override
  String get managerPinOnSubtitle =>
      'On — asked before deleting or changing a sale';

  @override
  String get managerPinSet => 'Set a PIN';

  @override
  String get managerPinChange => 'Change the PIN';

  @override
  String get managerPinRemove => 'Remove the PIN';

  @override
  String get managerPinNote =>
      'A short code asked before a sale is deleted, or its payment is changed. It is a speed bump, not a login — it will not stop someone who keeps the phone.';

  @override
  String get managerPinNew => 'New PIN (4 to 6 digits)';

  @override
  String get managerPinConfirm => 'Repeat the new PIN';

  @override
  String get managerPinEnter => 'Enter the manager PIN';

  @override
  String get managerPinUnlock => 'Unlock';

  @override
  String get managerPinInvalid => 'Use 4 to 6 digits';

  @override
  String get managerPinMismatch => 'The two PINs are not the same';

  @override
  String get managerPinWrong => 'Wrong PIN';

  @override
  String managerPinLocked(int seconds) {
    return 'Too many tries. Wait $seconds seconds.';
  }

  @override
  String get managerPinSaved => 'Manager PIN saved';

  @override
  String get managerPinRemoved => 'Manager PIN removed';

  @override
  String get managerPinForgot => 'Forgot the PIN?';

  @override
  String get managerPinResetTitle => 'Reset the manager PIN';

  @override
  String get managerPinResetIntro =>
      'Send your device number to support. They will give you a code that works today only. This works without internet.';

  @override
  String get managerPinResetCodeLabel => 'Reset code';

  @override
  String get managerPinResetWrong =>
      'This code is not right for this device today';

  @override
  String get managerPinResetDone =>
      'The PIN was removed. Set a new one from Settings.';

  @override
  String get lowStockAlertsTitle => 'Low stock alerts';

  @override
  String get lowStockAlertsSubtitle =>
      'Notify me when a product reaches its alert level. Needs an alert level on the product, and works only while the app is open.';

  @override
  String get lowStockAlertsDenied =>
      'Notifications are turned off for this app in the phone settings';

  @override
  String get lowStockTestAction => 'Send a test alert';

  @override
  String get lowStockTestSubtitle =>
      'Check that notifications reach this phone';

  @override
  String get lowStockTestTitle => 'Test alert';

  @override
  String get lowStockTestBody =>
      'If you can see this, low stock alerts are working.';

  @override
  String get lowStockTestSent => 'Sent — check your notifications';

  @override
  String get lowStockTestFailed => 'The phone did not accept the notification';

  @override
  String lowStockAlertOne(String name) {
    return '$name is running low';
  }

  @override
  String lowStockAlertRemaining(String qty) {
    return 'Only $qty left';
  }

  @override
  String lowStockAlertMany(int count) {
    return '$count products are running low';
  }

  @override
  String get managerBiometricTitle => 'Unlock with fingerprint';

  @override
  String get managerBiometricOn =>
      'On — your fingerprint or face opens the lock';

  @override
  String get managerBiometricOff => 'Off — the PIN is asked every time';

  @override
  String get managerBiometricUnavailable =>
      'No fingerprint or face is set up on this phone';

  @override
  String get managerBiometricReason =>
      'Confirm it is you to unlock the manager actions';

  @override
  String get managerBiometricFailed =>
      'Fingerprint not recognised — the PIN still works';

  @override
  String managerPinResetMessage(String id) {
    return 'I forgot the manager PIN of my Fawateer app. My device number: $id';
  }
}
