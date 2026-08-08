import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @posTab.
  ///
  /// In en, this message translates to:
  /// **'POS'**
  String get posTab;

  /// No description provided for @historyTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTab;

  /// No description provided for @productsTab.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsTab;

  /// No description provided for @customersTab.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @scannedItems.
  ///
  /// In en, this message translates to:
  /// **'Scanned Items'**
  String get scannedItems;

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear the invoice'**
  String get clearCart;

  /// No description provided for @clearCartTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear the whole invoice?'**
  String get clearCartTitle;

  /// No description provided for @clearCartBody.
  ///
  /// In en, this message translates to:
  /// **'All the scanned items will be removed. This cannot be undone.'**
  String get clearCartBody;

  /// No description provided for @clearCartConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearCartConfirm;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items total'**
  String itemsCount(String count);

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'TOTAL PRICE'**
  String get totalPrice;

  /// No description provided for @reviewOrder.
  ///
  /// In en, this message translates to:
  /// **'Review Order'**
  String get reviewOrder;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get cameraUnavailable;

  /// No description provided for @cameraPermissionHint.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access to scan barcodes, or add items manually below.'**
  String get cameraPermissionHint;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @cameraOff.
  ///
  /// In en, this message translates to:
  /// **'Camera is turned off'**
  String get cameraOff;

  /// No description provided for @cameraOffHint.
  ///
  /// In en, this message translates to:
  /// **'Turn on the camera to scan barcodes automatically.'**
  String get cameraOffHint;

  /// No description provided for @turnOnCamera.
  ///
  /// In en, this message translates to:
  /// **'Turn on Camera'**
  String get turnOnCamera;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get cartEmpty;

  /// No description provided for @cartEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Scanned items will appear here.'**
  String get cartEmptyHint;

  /// No description provided for @flash.
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get flash;

  /// No description provided for @invertScanLabel.
  ///
  /// In en, this message translates to:
  /// **'Light code'**
  String get invertScanLabel;

  /// No description provided for @invertScanHint.
  ///
  /// In en, this message translates to:
  /// **'Not scanning? Try light-barcode mode'**
  String get invertScanHint;

  /// No description provided for @pressBackAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackAgainToExit;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @colProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get colProduct;

  /// No description provided for @colPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get colPrice;

  /// No description provided for @colTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get colTotal;

  /// No description provided for @colSerial.
  ///
  /// In en, this message translates to:
  /// **'No.'**
  String get colSerial;

  /// No description provided for @colQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get colQty;

  /// No description provided for @colUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get colUnit;

  /// No description provided for @colUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get colUnitPrice;

  /// No description provided for @unitPiece.
  ///
  /// In en, this message translates to:
  /// **'pc'**
  String get unitPiece;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'GRAND TOTAL'**
  String get grandTotal;

  /// No description provided for @confirmSale.
  ///
  /// In en, this message translates to:
  /// **'Confirm Sale'**
  String get confirmSale;

  /// No description provided for @lowStockPrefix.
  ///
  /// In en, this message translates to:
  /// **'Low stock: '**
  String get lowStockPrefix;

  /// No description provided for @outOfStockPrefix.
  ///
  /// In en, this message translates to:
  /// **'Out of stock: '**
  String get outOfStockPrefix;

  /// No description provided for @insufficientStockError.
  ///
  /// In en, this message translates to:
  /// **'Can\'t complete the sale — some items exceed available stock'**
  String get insufficientStockError;

  /// No description provided for @saleConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Sale Confirmed!'**
  String get saleConfirmed;

  /// No description provided for @invoiceIdPrefix.
  ///
  /// In en, this message translates to:
  /// **'ID: ...'**
  String get invoiceIdPrefix;

  /// No description provided for @printReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print Receipt'**
  String get printReceipt;

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get newSale;

  /// No description provided for @shopNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Shop details not loaded'**
  String get shopNotLoaded;

  /// No description provided for @cartEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Add an item before confirming the sale.'**
  String get cartEmptyError;

  /// No description provided for @salesHistory.
  ///
  /// In en, this message translates to:
  /// **'Sales History'**
  String get salesHistory;

  /// No description provided for @todaysSales.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S SALES'**
  String get todaysSales;

  /// No description provided for @invoicesLabel.
  ///
  /// In en, this message translates to:
  /// **'invoices'**
  String get invoicesLabel;

  /// No description provided for @noSalesYet.
  ///
  /// In en, this message translates to:
  /// **'No sales yet'**
  String get noSalesYet;

  /// No description provided for @noSalesHint.
  ///
  /// In en, this message translates to:
  /// **'Completed sales will appear here.'**
  String get noSalesHint;

  /// No description provided for @historyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load sales history.'**
  String get historyLoadFailed;

  /// No description provided for @itemsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load items. Tap to retry.'**
  String get itemsLoadFailed;

  /// No description provided for @filterYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get filterYesterday;

  /// No description provided for @filterThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get filterThisWeek;

  /// No description provided for @filterThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get filterThisMonth;

  /// No description provided for @paymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentCash;

  /// No description provided for @paymentCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get paymentCredit;

  /// No description provided for @paymentType.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentType;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortBy;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get sortOldest;

  /// No description provided for @sortHighest.
  ///
  /// In en, this message translates to:
  /// **'Highest amount'**
  String get sortHighest;

  /// No description provided for @sortLowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest amount'**
  String get sortLowest;

  /// No description provided for @summaryInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get summaryInvoices;

  /// No description provided for @summaryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get summaryTotal;

  /// No description provided for @summaryCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get summaryCash;

  /// No description provided for @summaryCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get summaryCredit;

  /// No description provided for @summaryAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get summaryAverage;

  /// No description provided for @searchInvoicesHint.
  ///
  /// In en, this message translates to:
  /// **'Search invoice # or customer…'**
  String get searchInvoicesHint;

  /// No description provided for @noSalesMatch.
  ///
  /// In en, this message translates to:
  /// **'No sales match your filters.'**
  String get noSalesMatch;

  /// No description provided for @itemCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemCountLabel(int count);

  /// No description provided for @invoiceDetails.
  ///
  /// In en, this message translates to:
  /// **'Invoice Details'**
  String get invoiceDetails;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice #'**
  String get invoiceNumber;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @customerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customerLabel;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// No description provided for @walkInCustomer.
  ///
  /// In en, this message translates to:
  /// **'Walk-in customer'**
  String get walkInCustomer;

  /// No description provided for @reprint.
  ///
  /// In en, this message translates to:
  /// **'Reprint'**
  String get reprint;

  /// No description provided for @shopLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load shop details.'**
  String get shopLoadFailed;

  /// No description provided for @shopSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Please try again.'**
  String get shopSaveFailed;

  /// No description provided for @productsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search products…'**
  String get searchHint;

  /// No description provided for @tapToScan.
  ///
  /// In en, this message translates to:
  /// **'Tap the icon to open camera scanner'**
  String get tapToScan;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found. Add some!'**
  String get noProductsFound;

  /// No description provided for @noProductsMatch.
  ///
  /// In en, this message translates to:
  /// **'No products match your search.'**
  String get noProductsMatch;

  /// No description provided for @deleteProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProductTitle;

  /// No description provided for @deleteProductConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String deleteProductConfirm(String name);

  /// No description provided for @stockCountLabel.
  ///
  /// In en, this message translates to:
  /// **'In stock: {qty}'**
  String stockCountLabel(String qty);

  /// No description provided for @lowStockBadge.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStockBadge;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// No description provided for @noLowStockThresholds.
  ///
  /// In en, this message translates to:
  /// **'No product has a minimum set yet. Open a product and set its low-stock alert to use this filter.'**
  String get noLowStockThresholds;

  /// No description provided for @outOfStockBadge.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStockBadge;

  /// No description provided for @outOfStockScanNotice.
  ///
  /// In en, this message translates to:
  /// **'Out of stock: {name}'**
  String outOfStockScanNotice(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @quantityDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityDialogTitle;

  /// No description provided for @saleTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Sale type'**
  String get saleTypeLabel;

  /// No description provided for @saleTypePiece.
  ///
  /// In en, this message translates to:
  /// **'By piece'**
  String get saleTypePiece;

  /// No description provided for @saleTypeWeight.
  ///
  /// In en, this message translates to:
  /// **'By weight'**
  String get saleTypeWeight;

  /// No description provided for @pricePerKgLabel.
  ///
  /// In en, this message translates to:
  /// **'Price per kg'**
  String get pricePerKgLabel;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @weightFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightFieldLabel;

  /// No description provided for @amountFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountFieldLabel;

  /// No description provided for @addProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProductTitle;

  /// No description provided for @barcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode (optional)'**
  String get barcodeLabel;

  /// No description provided for @scanOrEnterBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan or enter barcode'**
  String get scanOrEnterBarcode;

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productNameLabel;

  /// No description provided for @productNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Basmati Rice'**
  String get productNameHint;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @costLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost (optional)'**
  String get costLabel;

  /// No description provided for @costHint.
  ///
  /// In en, this message translates to:
  /// **'Purchase cost, used for profit reports'**
  String get costHint;

  /// No description provided for @stockLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock Quantity (optional)'**
  String get stockLabel;

  /// No description provided for @stockHint.
  ///
  /// In en, this message translates to:
  /// **'Leave 0 to disable stock tracking'**
  String get stockHint;

  /// No description provided for @addProductBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProductBtn;

  /// No description provided for @barcodeExistsError.
  ///
  /// In en, this message translates to:
  /// **'A product with this barcode already exists!'**
  String get barcodeExistsError;

  /// No description provided for @lowStockAlertLabel.
  ///
  /// In en, this message translates to:
  /// **'Low-stock alert (optional)'**
  String get lowStockAlertLabel;

  /// No description provided for @lowStockAlertHint.
  ///
  /// In en, this message translates to:
  /// **'Warn when stock reaches this amount. 0 = off'**
  String get lowStockAlertHint;

  /// No description provided for @productAdded.
  ///
  /// In en, this message translates to:
  /// **'Product added'**
  String get productAdded;

  /// No description provided for @productUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product updated'**
  String get productUpdated;

  /// No description provided for @productDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product deleted'**
  String get productDeleted;

  /// No description provided for @errorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Please try again.'**
  String get errorSaveFailed;

  /// No description provided for @errorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load products.'**
  String get errorLoadFailed;

  /// No description provided for @editProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProductTitle;

  /// No description provided for @barcodeDisplay.
  ///
  /// In en, this message translates to:
  /// **'BARCODE'**
  String get barcodeDisplay;

  /// No description provided for @stockEditLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock Quantity'**
  String get stockEditLabel;

  /// No description provided for @stockEditHint.
  ///
  /// In en, this message translates to:
  /// **'Set to 0 to disable stock tracking'**
  String get stockEditHint;

  /// No description provided for @saveChangesBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesBtn;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @managementSection.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get managementSection;

  /// No description provided for @inventorySection.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventorySection;

  /// No description provided for @inventoryStrictTitle.
  ///
  /// In en, this message translates to:
  /// **'Block selling out of stock'**
  String get inventoryStrictTitle;

  /// No description provided for @inventoryStrictSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t allow selling more than what\'s on hand'**
  String get inventoryStrictSubtitle;

  /// No description provided for @showPrintButtonTitle.
  ///
  /// In en, this message translates to:
  /// **'Print receipts'**
  String get showPrintButtonTitle;

  /// No description provided for @showPrintButtonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the print button and auto-print on a sale. Turn off if you have no printer.'**
  String get showPrintButtonSubtitle;

  /// No description provided for @shopDetailsItem.
  ///
  /// In en, this message translates to:
  /// **'Shop Details'**
  String get shopDetailsItem;

  /// No description provided for @shopDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Edit business info & address'**
  String get shopDetailsSubtitle;

  /// No description provided for @cashboxItem.
  ///
  /// In en, this message translates to:
  /// **'Cashbox'**
  String get cashboxItem;

  /// No description provided for @cashboxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cash on hand, deposits & expenses'**
  String get cashboxSubtitle;

  /// No description provided for @cashboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Cashbox'**
  String get cashboxTitle;

  /// No description provided for @cashboxBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Current cash balance'**
  String get cashboxBalanceLabel;

  /// No description provided for @todayCashIn.
  ///
  /// In en, this message translates to:
  /// **'Today\'s cash in'**
  String get todayCashIn;

  /// No description provided for @todayCashOut.
  ///
  /// In en, this message translates to:
  /// **'Today\'s cash out'**
  String get todayCashOut;

  /// No description provided for @addDeposit.
  ///
  /// In en, this message translates to:
  /// **'Add deposit'**
  String get addDeposit;

  /// No description provided for @withdrawMoney.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdrawMoney;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get viewHistory;

  /// No description provided for @addCashTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get addCashTransaction;

  /// No description provided for @selectType.
  ///
  /// In en, this message translates to:
  /// **'Select type'**
  String get selectType;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentTransactions;

  /// No description provided for @noCashTransactions.
  ///
  /// In en, this message translates to:
  /// **'No cash transactions yet'**
  String get noCashTransactions;

  /// No description provided for @cashHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction history'**
  String get cashHistoryTitle;

  /// No description provided for @cashInflow.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get cashInflow;

  /// No description provided for @cashOutflow.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get cashOutflow;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterToday;

  /// No description provided for @filterDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get filterDateRange;

  /// No description provided for @filterByType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get filterByType;

  /// No description provided for @cashDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction?'**
  String get cashDeleteTitle;

  /// No description provided for @cashDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This cash transaction will be removed and the balance recalculated.'**
  String get cashDeleteConfirm;

  /// No description provided for @cashTransactionAdded.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved'**
  String get cashTransactionAdded;

  /// No description provided for @cashTransactionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get cashTransactionDeleted;

  /// No description provided for @cashDeleteNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Auto-created entries are removed by deleting their sale or payment'**
  String get cashDeleteNotAllowed;

  /// No description provided for @cashSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the transaction'**
  String get cashSaveFailed;

  /// No description provided for @cashLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the cashbox'**
  String get cashLoadFailed;

  /// No description provided for @cashTypeOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get cashTypeOpeningBalance;

  /// No description provided for @cashTypeCashSale.
  ///
  /// In en, this message translates to:
  /// **'Cash sale'**
  String get cashTypeCashSale;

  /// No description provided for @cashTypeCustomerDebtPayment.
  ///
  /// In en, this message translates to:
  /// **'Debt payment'**
  String get cashTypeCustomerDebtPayment;

  /// No description provided for @cashTypeManualDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get cashTypeManualDeposit;

  /// No description provided for @cashTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get cashTypeExpense;

  /// No description provided for @cashTypePersonalWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Personal withdrawal'**
  String get cashTypePersonalWithdrawal;

  /// No description provided for @cashTypePurchasePayment.
  ///
  /// In en, this message translates to:
  /// **'Purchase payment'**
  String get cashTypePurchasePayment;

  /// No description provided for @cashTypeSupplierPayment.
  ///
  /// In en, this message translates to:
  /// **'Supplier payment'**
  String get cashTypeSupplierPayment;

  /// No description provided for @cashTypeManualAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get cashTypeManualAdjustment;

  /// No description provided for @supportSection.
  ///
  /// In en, this message translates to:
  /// **'Support & About'**
  String get supportSection;

  /// No description provided for @contactSupportItem.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupportItem;

  /// No description provided for @contactSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get help with a problem or question'**
  String get contactSupportSubtitle;

  /// No description provided for @rateAppItem.
  ///
  /// In en, this message translates to:
  /// **'Rate the app'**
  String get rateAppItem;

  /// No description provided for @rateAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us how we are doing'**
  String get rateAppSubtitle;

  /// No description provided for @rateAppThanksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your rating'**
  String get rateAppThanksSubtitle;

  /// No description provided for @shareAppItem.
  ///
  /// In en, this message translates to:
  /// **'Share the app'**
  String get shareAppItem;

  /// No description provided for @shareAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send it to another shop owner'**
  String get shareAppSubtitle;

  /// No description provided for @shareAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Fawateer — a simple point-of-sale app for shops. Invoices, inventory, customer debts and reports, all offline.'**
  String get shareAppMessage;

  /// No description provided for @appVersionItem.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersionItem;

  /// No description provided for @aboutItem.
  ///
  /// In en, this message translates to:
  /// **'About Fawateer'**
  String get aboutItem;

  /// No description provided for @rateTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate Fawateer'**
  String get rateTitle;

  /// No description provided for @ratePrompt.
  ///
  /// In en, this message translates to:
  /// **'How is the app working for you?'**
  String get ratePrompt;

  /// No description provided for @rateCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment (optional)'**
  String get rateCommentHint;

  /// No description provided for @rateSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send rating'**
  String get rateSubmit;

  /// No description provided for @rateThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your rating was sent.'**
  String get rateThanks;

  /// No description provided for @rateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send your rating. Please try again.'**
  String get rateFailed;

  /// No description provided for @supportSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'How would you like to reach us?'**
  String get supportSheetTitle;

  /// No description provided for @supportWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get supportWhatsApp;

  /// No description provided for @supportTelegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get supportTelegram;

  /// No description provided for @supportEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get supportEmail;

  /// No description provided for @supportEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'Fawateer support request'**
  String get supportEmailSubject;

  /// No description provided for @supportLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open that app. Please try another way.'**
  String get supportLaunchFailed;

  /// No description provided for @poweredBy.
  ///
  /// In en, this message translates to:
  /// **'Developed by Evo Tech Systems'**
  String get poweredBy;

  /// No description provided for @visitWebsite.
  ///
  /// In en, this message translates to:
  /// **'evotech-sys.com'**
  String get visitWebsite;

  /// No description provided for @subscriptionActiveChip.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get subscriptionActiveChip;

  /// No description provided for @subscriptionInactiveChip.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get subscriptionInactiveChip;

  /// No description provided for @trialChip.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get trialChip;

  /// No description provided for @expiresOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expiresOnLabel;

  /// No description provided for @planLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planLabelShort;

  /// No description provided for @hardwareSection.
  ///
  /// In en, this message translates to:
  /// **'Hardware'**
  String get hardwareSection;

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// No description provided for @themeModeTitle.
  ///
  /// In en, this message translates to:
  /// **'App theme'**
  String get themeModeTitle;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get themeSystem;

  /// No description provided for @fontSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSizeTitle;

  /// No description provided for @fontSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get fontSizeSmall;

  /// No description provided for @fontSizeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get fontSizeNormal;

  /// No description provided for @fontSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get fontSizeLarge;

  /// No description provided for @fontSizeExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get fontSizeExtraLarge;

  /// No description provided for @printDeviceItem.
  ///
  /// In en, this message translates to:
  /// **'Print Device'**
  String get printDeviceItem;

  /// No description provided for @printerConnected.
  ///
  /// In en, this message translates to:
  /// **'Printer connected'**
  String get printerConnected;

  /// No description provided for @noPrinterConnected.
  ///
  /// In en, this message translates to:
  /// **'No printer connected'**
  String get noPrinterConnected;

  /// No description provided for @connectedBadge.
  ///
  /// In en, this message translates to:
  /// **'CONNECTED'**
  String get connectedBadge;

  /// No description provided for @bluetoothHint.
  ///
  /// In en, this message translates to:
  /// **'To connect: pair from phone Bluetooth settings, then tap Refresh.'**
  String get bluetoothHint;

  /// No description provided for @shopDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop Details'**
  String get shopDetailsTitle;

  /// No description provided for @generalInfo.
  ///
  /// In en, this message translates to:
  /// **'General Information'**
  String get generalInfo;

  /// No description provided for @receiptInfoNote.
  ///
  /// In en, this message translates to:
  /// **'These details will appear on your receipts.'**
  String get receiptInfoNote;

  /// No description provided for @shopNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Shop Name'**
  String get shopNameLabel;

  /// No description provided for @shopNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. QuickMart Superstore'**
  String get shopNameHint;

  /// No description provided for @address1Label.
  ///
  /// In en, this message translates to:
  /// **'Address Line 1'**
  String get address1Label;

  /// No description provided for @address1Hint.
  ///
  /// In en, this message translates to:
  /// **'Street / Area'**
  String get address1Hint;

  /// No description provided for @address2Label.
  ///
  /// In en, this message translates to:
  /// **'Address Line 2 (optional)'**
  String get address2Label;

  /// No description provided for @address2Hint.
  ///
  /// In en, this message translates to:
  /// **'City, ZIP code'**
  String get address2Hint;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneLabel;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'+1 555 000 0000'**
  String get phoneHint;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency Symbol'**
  String get currencyLabel;

  /// No description provided for @currencyHint.
  ///
  /// In en, this message translates to:
  /// **'ل.س  \$  €  £'**
  String get currencyHint;

  /// No description provided for @footerLabel.
  ///
  /// In en, this message translates to:
  /// **'Receipt Footer (optional)'**
  String get footerLabel;

  /// No description provided for @footerHint.
  ///
  /// In en, this message translates to:
  /// **'Thank you, visit again!'**
  String get footerHint;

  /// No description provided for @footerMaxChars.
  ///
  /// In en, this message translates to:
  /// **'Max 150 chars'**
  String get footerMaxChars;

  /// No description provided for @saveDetailsBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Details'**
  String get saveDetailsBtn;

  /// No description provided for @shopSaved.
  ///
  /// In en, this message translates to:
  /// **'Shop details saved!'**
  String get shopSaved;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get invalidPrice;

  /// No description provided for @negativePriceError.
  ///
  /// In en, this message translates to:
  /// **'Price cannot be negative'**
  String get negativePriceError;

  /// No description provided for @priceMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Price must be greater than zero'**
  String get priceMustBePositive;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get invalidNumber;

  /// No description provided for @negativeNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Cannot be negative'**
  String get negativeNotAllowed;

  /// No description provided for @printedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Printed successfully'**
  String get printedSuccessfully;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get noItems;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found: {barcode}'**
  String productNotFound(String barcode);

  /// No description provided for @unitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pieces — {product}'**
  String unitsTitle(String product);

  /// No description provided for @unitsSummary.
  ///
  /// In en, this message translates to:
  /// **'{available} of {total} still in stock'**
  String unitsSummary(int available, int total);

  /// No description provided for @unitsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get unitsAdd;

  /// No description provided for @unitsSerialLabel.
  ///
  /// In en, this message translates to:
  /// **'Serial number'**
  String get unitsSerialLabel;

  /// No description provided for @unitsSerialHint.
  ///
  /// In en, this message translates to:
  /// **'Scan or type the number'**
  String get unitsSerialHint;

  /// No description provided for @unitsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by serial number'**
  String get unitsSearchHint;

  /// No description provided for @unitsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items yet.\nAdd one for each piece you have in stock.'**
  String get unitsEmpty;

  /// No description provided for @unitsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No item matches that number.'**
  String get unitsNoMatch;

  /// No description provided for @serialLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get serialLabelShort;

  /// No description provided for @unitsNoSerial.
  ///
  /// In en, this message translates to:
  /// **'(no serial)'**
  String get unitsNoSerial;

  /// No description provided for @unitsSetWarranty.
  ///
  /// In en, this message translates to:
  /// **'Set warranty date'**
  String get unitsSetWarranty;

  /// No description provided for @unitsMarkDefective.
  ///
  /// In en, this message translates to:
  /// **'Mark as defective'**
  String get unitsMarkDefective;

  /// No description provided for @unitsRestock.
  ///
  /// In en, this message translates to:
  /// **'Return to stock'**
  String get unitsRestock;

  /// No description provided for @unitsWarrantyUntil.
  ///
  /// In en, this message translates to:
  /// **'Warranty until {date}'**
  String unitsWarrantyUntil(String date);

  /// No description provided for @unitsSoldOn.
  ///
  /// In en, this message translates to:
  /// **'Sold on {date}'**
  String unitsSoldOn(String date);

  /// No description provided for @unitStatusInStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get unitStatusInStock;

  /// No description provided for @unitStatusSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get unitStatusSold;

  /// No description provided for @unitStatusReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get unitStatusReturned;

  /// No description provided for @unitStatusDefective.
  ///
  /// In en, this message translates to:
  /// **'Defective'**
  String get unitStatusDefective;

  /// No description provided for @unitsAdded.
  ///
  /// In en, this message translates to:
  /// **'Item added'**
  String get unitsAdded;

  /// No description provided for @unitsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get unitsSaved;

  /// No description provided for @unitsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Item deleted'**
  String get unitsDeleted;

  /// No description provided for @unitsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the list.'**
  String get unitsLoadFailed;

  /// No description provided for @unitsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Please try again.'**
  String get unitsSaveFailed;

  /// No description provided for @unitsDuplicateSerial.
  ///
  /// In en, this message translates to:
  /// **'This number is already registered. Check whether you scanned the same piece twice.'**
  String get unitsDuplicateSerial;

  /// No description provided for @unitsDeleteBlockedSold.
  ///
  /// In en, this message translates to:
  /// **'This piece has been sold and cannot be deleted — its record links the serial number to its invoice.'**
  String get unitsDeleteBlockedSold;

  /// No description provided for @unitsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this piece?'**
  String get unitsDeleteTitle;

  /// No description provided for @unitsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from stock. This cannot be undone.'**
  String get unitsDeleteBody;

  /// No description provided for @productSerialized.
  ///
  /// In en, this message translates to:
  /// **'Each piece has its own serial number'**
  String get productSerialized;

  /// No description provided for @productSerializedHint.
  ///
  /// In en, this message translates to:
  /// **'Turn on for goods tracked one by one — phones, appliances, tools, gold. Stock is then counted from the pieces you add.'**
  String get productSerializedHint;

  /// No description provided for @productUnitsAction.
  ///
  /// In en, this message translates to:
  /// **'Pieces'**
  String get productUnitsAction;

  /// No description provided for @stockFromUnitsHint.
  ///
  /// In en, this message translates to:
  /// **'Counted from the units you add — open Units to change it.'**
  String get stockFromUnitsHint;

  /// No description provided for @unitNotAvailableError.
  ///
  /// In en, this message translates to:
  /// **'This piece (serial {serial}) is no longer in stock — it has already been sold.'**
  String unitNotAvailableError(String serial);

  /// No description provided for @unknownBarcodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Barcode not registered'**
  String get unknownBarcodeTitle;

  /// No description provided for @unknownBarcodeMessage.
  ///
  /// In en, this message translates to:
  /// **'This barcode does not exist: {barcode}\nDo you want to add it as a new product?'**
  String unknownBarcodeMessage(String barcode);

  /// No description provided for @unknownBarcodeAdd.
  ///
  /// In en, this message translates to:
  /// **'Add new product'**
  String get unknownBarcodeAdd;

  /// No description provided for @saleSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the sale. Please try again.'**
  String get saleSaveFailed;

  /// No description provided for @printerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No printer is connected.'**
  String get printerUnavailable;

  /// No description provided for @printFailed.
  ///
  /// In en, this message translates to:
  /// **'Printing failed. Please try again.'**
  String get printFailed;

  /// No description provided for @printerPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth permission is required.'**
  String get printerPermissionDenied;

  /// No description provided for @printerNoPairedDevices.
  ///
  /// In en, this message translates to:
  /// **'No paired printer found. Pair one in Bluetooth settings.'**
  String get printerNoPairedDevices;

  /// No description provided for @printerConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the printer.'**
  String get printerConnectFailed;

  /// No description provided for @printerScanFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not scan for printers.'**
  String get printerScanFailed;

  /// No description provided for @licenseChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking your subscription…'**
  String get licenseChecking;

  /// No description provided for @licenseErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network and try again.'**
  String get licenseErrorNetwork;

  /// No description provided for @licenseErrorServer.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t verify your subscription right now. Please try again.'**
  String get licenseErrorServer;

  /// No description provided for @licenseErrorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get licenseErrorUnexpected;

  /// No description provided for @activationTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate Fawateer'**
  String get activationTitle;

  /// No description provided for @activationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your details to verify your subscription, or choose a plan to get started.'**
  String get activationSubtitle;

  /// No description provided for @activationNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get activationNameLabel;

  /// No description provided for @activationPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get activationPhoneLabel;

  /// No description provided for @activationCheckButton.
  ///
  /// In en, this message translates to:
  /// **'Verify Activation'**
  String get activationCheckButton;

  /// No description provided for @activationViewPlans.
  ///
  /// In en, this message translates to:
  /// **'View Subscription Plans'**
  String get activationViewPlans;

  /// No description provided for @licenseExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription Expired'**
  String get licenseExpiredTitle;

  /// No description provided for @licenseExpiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Renew your subscription to keep using the app.'**
  String get licenseExpiredSubtitle;

  /// No description provided for @licenseExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String licenseExpiresOn(String date);

  /// No description provided for @plansTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription Plans'**
  String get plansTitle;

  /// No description provided for @plansEmpty.
  ///
  /// In en, this message translates to:
  /// **'No plans available right now.'**
  String get plansEmpty;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @planRecommended.
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get planRecommended;

  /// No description provided for @planDurationMonths.
  ///
  /// In en, this message translates to:
  /// **'{count} month(s)'**
  String planDurationMonths(int count);

  /// No description provided for @planSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get planSubscribe;

  /// No description provided for @planRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Your request was sent. We\'ll activate your device shortly.'**
  String get planRequestSent;

  /// No description provided for @contactMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact us to complete your subscription'**
  String get contactMethodTitle;

  /// No description provided for @contactWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get contactWhatsApp;

  /// No description provided for @contactTelegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get contactTelegram;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contactEmail;

  /// No description provided for @contactEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'Fawateer subscription request'**
  String get contactEmailSubject;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'A new update is available'**
  String get updateAvailableTitle;

  /// No description provided for @updateDownload.
  ///
  /// In en, this message translates to:
  /// **'Download update'**
  String get updateDownload;

  /// No description provided for @updateAvailableGeneric.
  ///
  /// In en, this message translates to:
  /// **'A new version of the app is available.'**
  String get updateAvailableGeneric;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @verifyRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription verification required'**
  String get verifyRequiredTitle;

  /// No description provided for @verifyOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'The app hasn\'t been able to reach the server for a while. Please connect to the internet, then tap Retry to continue.'**
  String get verifyOfflineMessage;

  /// No description provided for @verifyTamperMessage.
  ///
  /// In en, this message translates to:
  /// **'A change in the device\'s date and time was detected. Please correct the date and time, connect to the internet, then tap Retry.'**
  String get verifyTamperMessage;

  /// No description provided for @verifyDataSafe.
  ///
  /// In en, this message translates to:
  /// **'All your data is safe on this device.'**
  String get verifyDataSafe;

  /// No description provided for @verifyChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get verifyChecking;

  /// No description provided for @offlineWarnBanner.
  ///
  /// In en, this message translates to:
  /// **'No server connection for {days} days — connect to the internet to verify'**
  String offlineWarnBanner(int days);

  /// No description provided for @trialExpiredNotice.
  ///
  /// In en, this message translates to:
  /// **'Your free trial has ended. Choose a plan to activate a subscription and continue — all your data is safe.'**
  String get trialExpiredNotice;

  /// No description provided for @subscriptionExpiredNotice.
  ///
  /// In en, this message translates to:
  /// **'Your subscription has ended. Choose a plan to renew and continue — all your data is safe.'**
  String get subscriptionExpiredNotice;

  /// No description provided for @checkForUpdatesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to check for updates'**
  String get checkForUpdatesHint;

  /// No description provided for @updateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the latest version'**
  String get updateUpToDate;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates. Check your internet connection.'**
  String get updateCheckFailed;

  /// No description provided for @contactMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello,\nI\'d like to subscribe to Fawateer.\nPlan: {plan}\nName: {name}\nPhone: {phone}\nDevice ID: {deviceId}'**
  String contactMessage(
      String plan, String name, String phone, String deviceId);

  /// No description provided for @contactMessagePreview.
  ///
  /// In en, this message translates to:
  /// **'The message we\'ll send'**
  String get contactMessagePreview;

  /// No description provided for @contactLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open that app. Copy the message and send it to us manually.'**
  String get contactLaunchFailed;

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomer;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get editCustomer;

  /// No description provided for @customerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get customerNameLabel;

  /// No description provided for @customerPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get customerPhoneLabel;

  /// No description provided for @customerNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get customerNoteLabel;

  /// No description provided for @customerAdded.
  ///
  /// In en, this message translates to:
  /// **'Customer added'**
  String get customerAdded;

  /// No description provided for @customerUpdated.
  ///
  /// In en, this message translates to:
  /// **'Customer updated'**
  String get customerUpdated;

  /// No description provided for @customerDeleted.
  ///
  /// In en, this message translates to:
  /// **'Customer deleted'**
  String get customerDeleted;

  /// No description provided for @customerDeleteBlocked.
  ///
  /// In en, this message translates to:
  /// **'Can\'t delete a customer who has ledger entries.'**
  String get customerDeleteBlocked;

  /// No description provided for @customerSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Please try again.'**
  String get customerSaveFailed;

  /// No description provided for @customersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load customers.'**
  String get customersLoadFailed;

  /// No description provided for @noCustomers.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get noCustomers;

  /// No description provided for @noCustomersHint.
  ///
  /// In en, this message translates to:
  /// **'Add a customer to track credit sales and payments.'**
  String get noCustomersHint;

  /// No description provided for @searchCustomersHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone'**
  String get searchCustomersHint;

  /// No description provided for @noCustomerResults.
  ///
  /// In en, this message translates to:
  /// **'No customer matches this search'**
  String get noCustomerResults;

  /// No description provided for @selectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select customer'**
  String get selectCustomer;

  /// No description provided for @addNewCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add new customer'**
  String get addNewCustomer;

  /// No description provided for @searchCustomerHint.
  ///
  /// In en, this message translates to:
  /// **'Search customers'**
  String get searchCustomerHint;

  /// No description provided for @noMatchingCustomers.
  ///
  /// In en, this message translates to:
  /// **'No matching customers'**
  String get noMatchingCustomers;

  /// No description provided for @duplicateCustomerName.
  ///
  /// In en, this message translates to:
  /// **'A customer with this name already exists'**
  String get duplicateCustomerName;

  /// No description provided for @andMoreTypeToSearch.
  ///
  /// In en, this message translates to:
  /// **'+{count} more — type to search'**
  String andMoreTypeToSearch(int count);

  /// No description provided for @balanceSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get balanceSettled;

  /// No description provided for @balanceOwed.
  ///
  /// In en, this message translates to:
  /// **'Owes {amount}'**
  String balanceOwed(String amount);

  /// No description provided for @balanceCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit {amount}'**
  String balanceCredit(String amount);

  /// No description provided for @balanceOwedLabel.
  ///
  /// In en, this message translates to:
  /// **'Owes you'**
  String get balanceOwedLabel;

  /// No description provided for @balanceCreditLabel.
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get balanceCreditLabel;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// No description provided for @addDebt.
  ///
  /// In en, this message translates to:
  /// **'Add Debt'**
  String get addDebt;

  /// No description provided for @noLedgerEntries.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noLedgerEntries;

  /// No description provided for @entryPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get entryPayment;

  /// No description provided for @entryDebt.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get entryDebt;

  /// No description provided for @creditSaleTag.
  ///
  /// In en, this message translates to:
  /// **'Credit sale'**
  String get creditSaleTag;

  /// No description provided for @deleteEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get deleteEntryTitle;

  /// No description provided for @deleteEntryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this ledger entry?'**
  String get deleteEntryConfirm;

  /// No description provided for @deleteCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Customer'**
  String get deleteCustomerTitle;

  /// No description provided for @deleteCustomerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this customer? This can\'t be undone.'**
  String get deleteCustomerConfirm;

  /// No description provided for @debtAdded.
  ///
  /// In en, this message translates to:
  /// **'Debt added'**
  String get debtAdded;

  /// No description provided for @paymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get paymentRecorded;

  /// No description provided for @entryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get entryDeleted;

  /// No description provided for @ledgerSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Please try again.'**
  String get ledgerSaveFailed;

  /// No description provided for @ledgerLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the account.'**
  String get ledgerLoadFailed;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @amountMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero'**
  String get amountMustBePositive;

  /// No description provided for @sellOnCredit.
  ///
  /// In en, this message translates to:
  /// **'Sell on credit'**
  String get sellOnCredit;

  /// No description provided for @cashSale.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cashSale;

  /// No description provided for @chooseCustomer.
  ///
  /// In en, this message translates to:
  /// **'Choose customer'**
  String get chooseCustomer;

  /// No description provided for @creditToLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit — {name}'**
  String creditToLabel(String name);

  /// No description provided for @shareStatement.
  ///
  /// In en, this message translates to:
  /// **'Share statement'**
  String get shareStatement;

  /// No description provided for @statementCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Account statement'**
  String get statementCardTitle;

  /// No description provided for @statementMoreEntries.
  ///
  /// In en, this message translates to:
  /// **'…and {count} earlier entries'**
  String statementMoreEntries(int count);

  /// No description provided for @shareAsImage.
  ///
  /// In en, this message translates to:
  /// **'Share as image'**
  String get shareAsImage;

  /// No description provided for @shareAsText.
  ///
  /// In en, this message translates to:
  /// **'Share as text'**
  String get shareAsText;

  /// No description provided for @printStatement.
  ///
  /// In en, this message translates to:
  /// **'Print statement'**
  String get printStatement;

  /// No description provided for @statementPrinted.
  ///
  /// In en, this message translates to:
  /// **'Statement printed'**
  String get statementPrinted;

  /// No description provided for @statementHeader.
  ///
  /// In en, this message translates to:
  /// **'Account Statement — {shop}'**
  String statementHeader(String shop);

  /// No description provided for @statementDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get statementDate;

  /// No description provided for @statementTotalDebts.
  ///
  /// In en, this message translates to:
  /// **'Total debts'**
  String get statementTotalDebts;

  /// No description provided for @statementTotalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get statementTotalPaid;

  /// No description provided for @statementBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get statementBalance;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @accountInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get accountInfoSection;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @editAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit account details'**
  String get editAccountTitle;

  /// No description provided for @agentSavedSynced.
  ///
  /// In en, this message translates to:
  /// **'Saved and synced with the server'**
  String get agentSavedSynced;

  /// No description provided for @agentSavedLocal.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device — couldn\'t reach the server'**
  String get agentSavedLocal;

  /// No description provided for @subscriptionItem.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionItem;

  /// No description provided for @subscriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View status & renew your plan'**
  String get subscriptionSubtitle;

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionTitle;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusTrial.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get statusTrial;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Not activated'**
  String get statusInactive;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String daysRemaining(int days);

  /// No description provided for @lastChecked.
  ///
  /// In en, this message translates to:
  /// **'Last checked: {date}'**
  String lastChecked(String date);

  /// No description provided for @neverChecked.
  ///
  /// In en, this message translates to:
  /// **'never'**
  String get neverChecked;

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get refreshStatus;

  /// No description provided for @renewSubscription.
  ///
  /// In en, this message translates to:
  /// **'Renew / change plan'**
  String get renewSubscription;

  /// No description provided for @deviceIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get deviceIdLabel;

  /// No description provided for @deviceIdHint.
  ///
  /// In en, this message translates to:
  /// **'Send this ID to support to activate your device.'**
  String get deviceIdHint;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @subscriptionActivatedBanner.
  ///
  /// In en, this message translates to:
  /// **'Your subscription has been activated'**
  String get subscriptionActivatedBanner;

  /// No description provided for @trialBannerNoDate.
  ///
  /// In en, this message translates to:
  /// **'Free trial'**
  String get trialBannerNoDate;

  /// No description provided for @trialBannerWithDate.
  ///
  /// In en, this message translates to:
  /// **'Free trial — {days} days left (until {date})'**
  String trialBannerWithDate(int days, String date);

  /// No description provided for @trialBanner.
  ///
  /// In en, this message translates to:
  /// **'Free trial — {days} days left'**
  String trialBanner(int days);

  /// No description provided for @trialUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get trialUpgrade;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupTitle;

  /// No description provided for @backupItem.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupItem;

  /// No description provided for @backupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Protect your data with Google Drive'**
  String get backupSubtitle;

  /// No description provided for @backupSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your Google account to keep a safe copy of all your data (sales, products, customers, debts, cash) in your own Google Drive. If your phone is lost or broken, you can restore everything on a new device.'**
  String get backupSignInPrompt;

  /// No description provided for @backupAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Your previous backups are on the account {account}'**
  String backupAccountHint(String account);

  /// No description provided for @backupSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get backupSignInButton;

  /// No description provided for @backupSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get backupSignOut;

  /// No description provided for @backupAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Signed-in account'**
  String get backupAccountLabel;

  /// No description provided for @backupNowButton.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupNowButton;

  /// No description provided for @backupAutoTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic daily backup'**
  String get backupAutoTitle;

  /// No description provided for @backupAutoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Backs up once a day when the app is opened and you are online.'**
  String get backupAutoSubtitle;

  /// No description provided for @backupExportButton.
  ///
  /// In en, this message translates to:
  /// **'Export a copy to share'**
  String get backupExportButton;

  /// No description provided for @backupLastLabel.
  ///
  /// In en, this message translates to:
  /// **'Last backup'**
  String get backupLastLabel;

  /// No description provided for @backupNever.
  ///
  /// In en, this message translates to:
  /// **'No backup yet — your data is not protected'**
  String get backupNever;

  /// No description provided for @backupListTitle.
  ///
  /// In en, this message translates to:
  /// **'Your backups'**
  String get backupListTitle;

  /// No description provided for @backupListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No backups found in this account'**
  String get backupListEmpty;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupRestore;

  /// No description provided for @backupThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get backupThisDevice;

  /// No description provided for @backupRestoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup?'**
  String get backupRestoreConfirmTitle;

  /// No description provided for @backupRestoreConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will replace ALL current data on this device with the selected backup. This cannot be undone. The app will close so you can reopen it fresh.'**
  String get backupRestoreConfirmBody;

  /// No description provided for @backupRestartTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore complete'**
  String get backupRestartTitle;

  /// No description provided for @backupRestartBody.
  ///
  /// In en, this message translates to:
  /// **'Your data has been restored. Please reopen the app to finish.'**
  String get backupRestartBody;

  /// No description provided for @backupRestartAction.
  ///
  /// In en, this message translates to:
  /// **'Close app'**
  String get backupRestartAction;

  /// No description provided for @backupRestoreFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore did not finish'**
  String get backupRestoreFailedTitle;

  /// No description provided for @backupRestoreFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Your data has NOT been changed — it is safe exactly as it was. The app still needs to be reopened before it will work again.'**
  String get backupRestoreFailedBody;

  /// No description provided for @backupSuccessBackedUp.
  ///
  /// In en, this message translates to:
  /// **'Backup completed successfully'**
  String get backupSuccessBackedUp;

  /// No description provided for @backupSuccessExported.
  ///
  /// In en, this message translates to:
  /// **'Copy ready — choose where to share it'**
  String get backupSuccessExported;

  /// No description provided for @backupErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Connect and try again.'**
  String get backupErrorNetwork;

  /// No description provided for @backupErrorServer.
  ///
  /// In en, this message translates to:
  /// **'Google Drive error. Please try again.'**
  String get backupErrorServer;

  /// No description provided for @backupErrorSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled or not completed.'**
  String get backupErrorSignIn;

  /// No description provided for @backupErrorIncompatibleNew.
  ///
  /// In en, this message translates to:
  /// **'This backup was made by a newer version of the app. Please update the app before restoring.'**
  String get backupErrorIncompatibleNew;

  /// No description provided for @backupErrorCorrupt.
  ///
  /// In en, this message translates to:
  /// **'This backup file is damaged and cannot be restored.'**
  String get backupErrorCorrupt;

  /// No description provided for @backupErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get backupErrorUnknown;

  /// No description provided for @backupBusyBackingUp.
  ///
  /// In en, this message translates to:
  /// **'Backing up…'**
  String get backupBusyBackingUp;

  /// No description provided for @backupBusyRestoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get backupBusyRestoring;

  /// No description provided for @priceCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Price currency'**
  String get priceCurrencyLabel;

  /// No description provided for @currencySp.
  ///
  /// In en, this message translates to:
  /// **'SP'**
  String get currencySp;

  /// No description provided for @currencyUsd.
  ///
  /// In en, this message translates to:
  /// **'USD'**
  String get currencyUsd;

  /// No description provided for @currencySettingsItem.
  ///
  /// In en, this message translates to:
  /// **'Currency & Exchange Rate'**
  String get currencySettingsItem;

  /// No description provided for @currencySettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set the USD → SP rate for dollar-priced products'**
  String get currencySettingsSubtitle;

  /// No description provided for @currencySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Currency & Exchange Rate'**
  String get currencySettingsTitle;

  /// No description provided for @currencySettingsNote.
  ///
  /// In en, this message translates to:
  /// **'Syrian Pound is your main currency. Products priced in US Dollars are converted to SP at this rate when you sell them. Changing the rate only affects new sales — past invoices keep their original rate.'**
  String get currencySettingsNote;

  /// No description provided for @exchangeRateLabel.
  ///
  /// In en, this message translates to:
  /// **'SP per 1 USD'**
  String get exchangeRateLabel;

  /// No description provided for @exchangeRateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 15000'**
  String get exchangeRateHint;

  /// No description provided for @exchangeRateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a rate greater than zero'**
  String get exchangeRateInvalid;

  /// No description provided for @exchangeRateSaved.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate saved'**
  String get exchangeRateSaved;

  /// No description provided for @exchangeRateNever.
  ///
  /// In en, this message translates to:
  /// **'Not set yet'**
  String get exchangeRateNever;

  /// No description provided for @setExchangeRateShort.
  ///
  /// In en, this message translates to:
  /// **'Set \$ rate'**
  String get setExchangeRateShort;

  /// No description provided for @exchangeRateUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String exchangeRateUpdatedAt(String date);

  /// No description provided for @exchangeRateMissingError.
  ///
  /// In en, this message translates to:
  /// **'Set the USD exchange rate in Settings → Currency before selling a dollar-priced item.'**
  String get exchangeRateMissingError;

  /// No description provided for @discountTitle.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountTitle;

  /// No description provided for @discountPercent.
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get discountPercent;

  /// No description provided for @discountAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get discountAmount;

  /// No description provided for @discountValueHint.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get discountValueHint;

  /// No description provided for @discountApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get discountApply;

  /// No description provided for @discountRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get discountRemove;

  /// No description provided for @addDiscountAction.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get addDiscountAction;

  /// No description provided for @discountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountLabel;

  /// No description provided for @subtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotalLabel;

  /// No description provided for @cartDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Cart discount'**
  String get cartDiscountLabel;

  /// No description provided for @shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareAction;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t prepare the share — please try again'**
  String get shareFailed;

  /// No description provided for @estimatedProfit.
  ///
  /// In en, this message translates to:
  /// **'Estimated profit'**
  String get estimatedProfit;

  /// No description provided for @openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get openingBalance;

  /// No description provided for @closingBalance.
  ///
  /// In en, this message translates to:
  /// **'Closing balance'**
  String get closingBalance;

  /// No description provided for @cashboxDailySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily cashbox summary'**
  String get cashboxDailySummaryTitle;

  /// No description provided for @salesSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales summary'**
  String get salesSummaryTitle;

  /// No description provided for @reportPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get reportPeriodLabel;

  /// No description provided for @receiptThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your business'**
  String get receiptThankYou;

  /// No description provided for @reportsTab.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTab;

  /// No description provided for @dashboardTab.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTab;

  /// No description provided for @salesTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get salesTabLabel;

  /// No description provided for @filterLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get filterLast7Days;

  /// No description provided for @filterLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get filterLast30Days;

  /// No description provided for @revenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenueLabel;

  /// No description provided for @outstandingDebtsLabel.
  ///
  /// In en, this message translates to:
  /// **'Outstanding debts'**
  String get outstandingDebtsLabel;

  /// No description provided for @inventoryValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Inventory value'**
  String get inventoryValueLabel;

  /// No description provided for @salesTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales trend'**
  String get salesTrendTitle;

  /// No description provided for @topProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top products'**
  String get topProductsTitle;

  /// No description provided for @cashFlowTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash flow'**
  String get cashFlowTitle;

  /// No description provided for @lowStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStockTitle;

  /// No description provided for @topDebtorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top debtors'**
  String get topDebtorsTitle;

  /// No description provided for @metricQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get metricQuantity;

  /// No description provided for @metricProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get metricProfit;

  /// No description provided for @cashInLabel.
  ///
  /// In en, this message translates to:
  /// **'Cash in'**
  String get cashInLabel;

  /// No description provided for @cashOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Cash out'**
  String get cashOutLabel;

  /// No description provided for @expensesLabel.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesLabel;

  /// No description provided for @withdrawalsLabel.
  ///
  /// In en, this message translates to:
  /// **'Withdrawals'**
  String get withdrawalsLabel;

  /// No description provided for @dashboardNoData.
  ///
  /// In en, this message translates to:
  /// **'No sales in this period yet'**
  String get dashboardNoData;

  /// No description provided for @dashboardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the dashboard'**
  String get dashboardLoadFailed;

  /// No description provided for @unitsSuffix.
  ///
  /// In en, this message translates to:
  /// **'{count} sold'**
  String unitsSuffix(String count);

  /// No description provided for @scanBarcodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcodeTitle;

  /// No description provided for @alignBarcodeHint.
  ///
  /// In en, this message translates to:
  /// **'Align barcode within frame'**
  String get alignBarcodeHint;

  /// No description provided for @productFieldsItem.
  ///
  /// In en, this message translates to:
  /// **'Product fields'**
  String get productFieldsItem;

  /// No description provided for @productFieldsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Custom info stored per product'**
  String get productFieldsSubtitle;

  /// No description provided for @productFieldsTitle.
  ///
  /// In en, this message translates to:
  /// **'Product fields'**
  String get productFieldsTitle;

  /// No description provided for @productFieldsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No custom fields yet'**
  String get productFieldsEmpty;

  /// No description provided for @productFieldsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add fields like Color or Storage, or start from a business template.'**
  String get productFieldsEmptyHint;

  /// No description provided for @addFieldBtn.
  ///
  /// In en, this message translates to:
  /// **'Add field'**
  String get addFieldBtn;

  /// No description provided for @useTemplateBtn.
  ///
  /// In en, this message translates to:
  /// **'Start from a template'**
  String get useTemplateBtn;

  /// No description provided for @chooseBusinessType.
  ///
  /// In en, this message translates to:
  /// **'Choose your business type'**
  String get chooseBusinessType;

  /// No description provided for @templateSeedNote.
  ///
  /// In en, this message translates to:
  /// **'Adds recommended fields. You can edit or remove them anytime.'**
  String get templateSeedNote;

  /// No description provided for @fieldNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Field name'**
  String get fieldNameLabel;

  /// No description provided for @fieldNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Color, Storage, Warranty'**
  String get fieldNameHint;

  /// No description provided for @fieldTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Field type'**
  String get fieldTypeLabel;

  /// No description provided for @fieldUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit (optional)'**
  String get fieldUnitLabel;

  /// No description provided for @fieldUnitHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. GB, ml, V'**
  String get fieldUnitHint;

  /// No description provided for @fieldOptionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Choices'**
  String get fieldOptionsLabel;

  /// No description provided for @fieldOptionsHint.
  ///
  /// In en, this message translates to:
  /// **'Separate choices with commas'**
  String get fieldOptionsHint;

  /// No description provided for @fieldRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequiredLabel;

  /// No description provided for @fieldShowInListLabel.
  ///
  /// In en, this message translates to:
  /// **'Show in product list'**
  String get fieldShowInListLabel;

  /// No description provided for @fieldShowOnReceiptLabel.
  ///
  /// In en, this message translates to:
  /// **'Show on receipt'**
  String get fieldShowOnReceiptLabel;

  /// No description provided for @fieldArchiveAction.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get fieldArchiveAction;

  /// No description provided for @fieldUnarchiveAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get fieldUnarchiveAction;

  /// No description provided for @fieldDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get fieldDeleteAction;

  /// No description provided for @fieldArchivedBadge.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get fieldArchivedBadge;

  /// No description provided for @attrTypeText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get attrTypeText;

  /// No description provided for @attrTypeNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get attrTypeNumber;

  /// No description provided for @attrTypeSelect.
  ///
  /// In en, this message translates to:
  /// **'Choice list'**
  String get attrTypeSelect;

  /// No description provided for @attrTypeBoolean.
  ///
  /// In en, this message translates to:
  /// **'Yes / No'**
  String get attrTypeBoolean;

  /// No description provided for @attrTypeDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get attrTypeDate;

  /// No description provided for @templateAppliedMsg.
  ///
  /// In en, this message translates to:
  /// **'Fields added'**
  String get templateAppliedMsg;

  /// No description provided for @showArchivedFields.
  ///
  /// In en, this message translates to:
  /// **'Show archived'**
  String get showArchivedFields;

  /// No description provided for @filterProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter products'**
  String get filterProductsTitle;

  /// No description provided for @clearFiltersBtn.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearFiltersBtn;

  /// No description provided for @noFilterableFields.
  ///
  /// In en, this message translates to:
  /// **'No filterable fields. Add a choice-list field to filter by it.'**
  String get noFilterableFields;

  /// No description provided for @salesByFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales by field'**
  String get salesByFieldTitle;

  /// No description provided for @salesByFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a field to break sales down by its values.'**
  String get salesByFieldHint;

  /// No description provided for @reportFieldNone.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get reportFieldNone;

  /// No description provided for @printLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Print label'**
  String get printLabelTitle;

  /// No description provided for @printLabelAction.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printLabelAction;

  /// No description provided for @labelCopies.
  ///
  /// In en, this message translates to:
  /// **'Copies'**
  String get labelCopies;

  /// No description provided for @labelBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get labelBarcode;

  /// No description provided for @labelQr.
  ///
  /// In en, this message translates to:
  /// **'QR'**
  String get labelQr;

  /// No description provided for @labelPrinted.
  ///
  /// In en, this message translates to:
  /// **'Label sent to the printer'**
  String get labelPrinted;

  /// No description provided for @labelPrintFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t print — check the printer connection'**
  String get labelPrintFailed;

  /// No description provided for @unknownBarcodeSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get unknownBarcodeSearch;

  /// No description provided for @productNameExistsError.
  ///
  /// In en, this message translates to:
  /// **'A product with this name already exists'**
  String get productNameExistsError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
