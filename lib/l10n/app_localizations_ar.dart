// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get posTab => 'نقطة البيع';

  @override
  String get historyTab => 'السجل';

  @override
  String get productsTab => 'المنتجات';

  @override
  String get settingsTab => 'الإعدادات';

  @override
  String get scannedItems => 'المنتجات الممسوحة';

  @override
  String itemsCount(String count) {
    return '$count منتج';
  }

  @override
  String get totalPrice => 'إجمالي السعر';

  @override
  String get reviewOrder => 'مراجعة الطلب';

  @override
  String get cameraOff => 'الكاميرا متوقفة';

  @override
  String get cameraOffHint => 'شغّل الكاميرا لمسح الباركود تلقائياً.';

  @override
  String get turnOnCamera => 'تشغيل الكاميرا';

  @override
  String get cartEmpty => 'القائمة فارغة';

  @override
  String get cartEmptyHint => 'تظهر هنا المنتجات الممسوحة.';

  @override
  String get flash => 'فلاش';

  @override
  String get camera => 'كاميرا';

  @override
  String get addItem => 'إضافة صنف';

  @override
  String get checkoutTitle => 'إتمام البيع';

  @override
  String get colProduct => 'المنتج';

  @override
  String get colPrice => 'السعر';

  @override
  String get colTotal => 'المجموع';

  @override
  String get grandTotal => 'المجموع الكلي';

  @override
  String get confirmSale => 'تأكيد البيع';

  @override
  String get lowStockPrefix => 'مخزون منخفض: ';

  @override
  String get saleConfirmed => 'تم تأكيد البيع!';

  @override
  String get invoiceIdPrefix => 'رقم: ...';

  @override
  String get printReceipt => 'طباعة الفاتورة';

  @override
  String get newSale => 'بيع جديد';

  @override
  String get shopNotLoaded => 'لم تُحمَّل بيانات المحل';

  @override
  String get cartEmptyError => 'أضف صنفاً قبل تأكيد البيع.';

  @override
  String get salesHistory => 'سجل المبيعات';

  @override
  String get todaysSales => 'مبيعات اليوم';

  @override
  String get invoicesLabel => 'فاتورة';

  @override
  String get noSalesYet => 'لا توجد مبيعات بعد';

  @override
  String get noSalesHint => 'ستظهر هنا المبيعات المكتملة.';

  @override
  String get productsTitle => 'المنتجات';

  @override
  String get searchHint => 'ابحث عن منتج…';

  @override
  String get tapToScan => 'اضغط الأيقونة لفتح الكاميرا';

  @override
  String get noProductsFound => 'لا توجد منتجات. أضف منتجاً!';

  @override
  String get noProductsMatch => 'لا توجد منتجات تطابق بحثك.';

  @override
  String get deleteProductTitle => 'حذف المنتج';

  @override
  String deleteProductConfirm(String name) {
    return 'هل تريد حذف $name؟';
  }

  @override
  String stockCountLabel(String qty) {
    return 'المتوفر: $qty';
  }

  @override
  String get lowStockBadge => 'مخزون منخفض';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get save => 'حفظ';

  @override
  String get quantityDialogTitle => 'الكمية';

  @override
  String get addProductTitle => 'إضافة منتج';

  @override
  String get barcodeLabel => 'الباركود (اختياري)';

  @override
  String get scanOrEnterBarcode => 'امسح أو أدخل الباركود';

  @override
  String get productNameLabel => 'اسم المنتج';

  @override
  String get productNameHint => 'مثال: أرز بسمتي';

  @override
  String get priceLabel => 'السعر';

  @override
  String get costLabel => 'التكلفة (اختياري)';

  @override
  String get costHint => 'تكلفة الشراء، تُستخدم لتقارير الأرباح';

  @override
  String get stockLabel => 'الكمية المتوفرة (اختياري)';

  @override
  String get stockHint => 'اترك 0 لتعطيل تتبع المخزون';

  @override
  String get addProductBtn => 'إضافة المنتج';

  @override
  String get barcodeExistsError => 'يوجد منتج بهذا الباركود مسبقاً!';

  @override
  String get lowStockAlertLabel => 'تنبيه المخزون المنخفض (اختياري)';

  @override
  String get lowStockAlertHint =>
      'نبّهني عند وصول المخزون لهذا الحد. 0 = إيقاف';

  @override
  String get productAdded => 'تمت إضافة المنتج';

  @override
  String get productUpdated => 'تم تحديث المنتج';

  @override
  String get productDeleted => 'تم حذف المنتج';

  @override
  String get errorSaveFailed => 'تعذّر الحفظ. حاول مرة أخرى.';

  @override
  String get errorLoadFailed => 'تعذّر تحميل المنتجات.';

  @override
  String get editProductTitle => 'تعديل المنتج';

  @override
  String get barcodeDisplay => 'الباركود';

  @override
  String get stockEditLabel => 'الكمية المتوفرة';

  @override
  String get stockEditHint => 'اضبط على 0 لتعطيل تتبع المخزون';

  @override
  String get saveChangesBtn => 'حفظ التعديلات';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get managementSection => 'الإدارة';

  @override
  String get shopDetailsItem => 'تفاصيل المحل';

  @override
  String get shopDetailsSubtitle => 'تعديل معلومات المحل والعنوان';

  @override
  String get hardwareSection => 'الأجهزة';

  @override
  String get printDeviceItem => 'جهاز الطباعة';

  @override
  String get printerConnected => 'الطابعة متصلة';

  @override
  String get noPrinterConnected => 'لا توجد طابعة متصلة';

  @override
  String get connectedBadge => 'متصل';

  @override
  String get bluetoothHint =>
      'للتوصيل: قم بالإقران من إعدادات البلوتوث، ثم اضغط تحديث.';

  @override
  String get shopDetailsTitle => 'تفاصيل المحل';

  @override
  String get generalInfo => 'معلومات عامة';

  @override
  String get receiptInfoNote => 'تظهر هذه التفاصيل على إيصالاتك.';

  @override
  String get shopNameLabel => 'اسم المحل';

  @override
  String get shopNameHint => 'مثال: سوبر ماركت السريع';

  @override
  String get address1Label => 'العنوان الأول';

  @override
  String get address1Hint => 'الشارع / المنطقة';

  @override
  String get address2Label => 'العنوان الثاني (اختياري)';

  @override
  String get address2Hint => 'المدينة، الرمز البريدي';

  @override
  String get phoneLabel => 'رقم الهاتف';

  @override
  String get phoneHint => 'مثال: 0500000000';

  @override
  String get currencyLabel => 'رمز العملة';

  @override
  String get currencyHint => 'ر.س  \$  €  £';

  @override
  String get footerLabel => 'نص تذييل الإيصال (اختياري)';

  @override
  String get footerHint => 'شكراً، زورونا مجدداً!';

  @override
  String get footerMaxChars => 'الحد الأقصى 150 حرف';

  @override
  String get saveDetailsBtn => 'حفظ التفاصيل';

  @override
  String get shopSaved => 'تم حفظ تفاصيل المحل!';

  @override
  String get fieldRequired => 'مطلوب';

  @override
  String get invalidPrice => 'الرجاء إدخال سعر صحيح';

  @override
  String get negativePriceError => 'السعر لا يمكن أن يكون سالباً';

  @override
  String get invalidNumber => 'الرجاء إدخال رقم صحيح';

  @override
  String get negativeNotAllowed => 'لا يمكن أن يكون سالباً';

  @override
  String get printedSuccessfully => 'تمت الطباعة بنجاح';

  @override
  String get noItems => 'لا توجد عناصر';

  @override
  String productNotFound(String barcode) {
    return 'المنتج غير موجود: $barcode';
  }

  @override
  String get saleSaveFailed => 'تعذّر حفظ عملية البيع. حاول مرة أخرى.';

  @override
  String get printerUnavailable => 'لا توجد طابعة متصلة.';

  @override
  String get printFailed => 'فشلت الطباعة. حاول مرة أخرى.';

  @override
  String get printerPermissionDenied => 'إذن البلوتوث مطلوب.';

  @override
  String get printerNoPairedDevices =>
      'لا توجد طابعة مقترنة. قم بالإقران من إعدادات البلوتوث.';

  @override
  String get printerConnectFailed => 'تعذّر الاتصال بالطابعة.';

  @override
  String get printerScanFailed => 'تعذّر البحث عن الطابعات.';
}
