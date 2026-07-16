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

  /// No description provided for @hardwareSection.
  ///
  /// In en, this message translates to:
  /// **'Hardware'**
  String get hardwareSection;

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

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @contactMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello, I\'d like to subscribe to the {plan} plan for Fawateer.'**
  String contactMessage(String plan);

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
