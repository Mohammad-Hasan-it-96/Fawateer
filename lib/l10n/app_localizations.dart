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
  String itemsCount(int count);

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

  /// No description provided for @addProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProductTitle;

  /// No description provided for @barcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
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
  /// **'₹  \$  €  £'**
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
