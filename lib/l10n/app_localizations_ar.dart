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
  String get customersTab => 'العملاء';

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
  String get cameraUnavailable => 'الكاميرا غير متاحة';

  @override
  String get cameraPermissionHint =>
      'اسمح بالوصول إلى الكاميرا لمسح الباركود، أو أضف الأصناف يدوياً بالأسفل.';

  @override
  String get openSettings => 'فتح الإعدادات';

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
  String get invertScanLabel => 'باركود فاتح';

  @override
  String get invertScanHint => 'لا يُقرأ الباركود؟ جرّب وضع «باركود فاتح»';

  @override
  String get pressBackAgainToExit => 'اضغط رجوع مرة أخرى للخروج';

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
  String get colSerial => 'م';

  @override
  String get colQty => 'الكمية';

  @override
  String get colUnit => 'الوحدة';

  @override
  String get colUnitPrice => 'الإفرادي';

  @override
  String get unitPiece => 'قطعة';

  @override
  String get grandTotal => 'المجموع الكلي';

  @override
  String get confirmSale => 'تأكيد البيع';

  @override
  String get lowStockPrefix => 'مخزون منخفض: ';

  @override
  String get outOfStockPrefix => 'نفد المخزون: ';

  @override
  String get insufficientStockError =>
      'تعذّر إتمام البيع — بعض الأصناف تتجاوز الكمية المتوفرة';

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
  String get historyLoadFailed => 'تعذّر تحميل سجل المبيعات.';

  @override
  String get itemsLoadFailed => 'تعذّر تحميل الأصناف. اضغط لإعادة المحاولة.';

  @override
  String get filterYesterday => 'أمس';

  @override
  String get filterThisWeek => 'هذا الأسبوع';

  @override
  String get filterThisMonth => 'هذا الشهر';

  @override
  String get paymentCash => 'نقدي';

  @override
  String get paymentCredit => 'آجل';

  @override
  String get paymentType => 'الدفع';

  @override
  String get sortBy => 'ترتيب';

  @override
  String get sortNewest => 'الأحدث';

  @override
  String get sortOldest => 'الأقدم';

  @override
  String get sortHighest => 'الأعلى قيمة';

  @override
  String get sortLowest => 'الأقل قيمة';

  @override
  String get summaryInvoices => 'الفواتير';

  @override
  String get summaryTotal => 'الإجمالي';

  @override
  String get summaryCash => 'نقدي';

  @override
  String get summaryCredit => 'آجل';

  @override
  String get summaryAverage => 'المتوسط';

  @override
  String get searchInvoicesHint => 'ابحث برقم الفاتورة أو اسم العميل…';

  @override
  String get noSalesMatch => 'لا توجد مبيعات مطابقة للتصفية.';

  @override
  String itemCountLabel(int count) {
    return '$count صنف';
  }

  @override
  String get invoiceDetails => 'تفاصيل الفاتورة';

  @override
  String get invoiceNumber => 'رقم الفاتورة';

  @override
  String get dateLabel => 'التاريخ';

  @override
  String get timeLabel => 'الوقت';

  @override
  String get customerLabel => 'العميل';

  @override
  String get unitPrice => 'سعر الوحدة';

  @override
  String get walkInCustomer => 'عميل نقدي';

  @override
  String get reprint => 'إعادة الطباعة';

  @override
  String get shopLoadFailed => 'تعذّر تحميل بيانات المحل.';

  @override
  String get shopSaveFailed => 'تعذّر الحفظ. حاول مرة أخرى.';

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
  String get outOfStockBadge => 'منتهي';

  @override
  String outOfStockScanNotice(String name) {
    return 'انتهت كمية المنتج: $name';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get save => 'حفظ';

  @override
  String get quantityDialogTitle => 'الكمية';

  @override
  String get saleTypeLabel => 'نوع البيع';

  @override
  String get saleTypePiece => 'بالقطعة';

  @override
  String get saleTypeWeight => 'بالوزن';

  @override
  String get pricePerKgLabel => 'السعر لكل كغ';

  @override
  String get unitKg => 'كغ';

  @override
  String get weightFieldLabel => 'الوزن (كغ)';

  @override
  String get amountFieldLabel => 'المبلغ';

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
  String get inventorySection => 'المخزون';

  @override
  String get inventoryStrictTitle => 'منع البيع عند نفاد المخزون';

  @override
  String get inventoryStrictSubtitle => 'لا تسمح ببيع كمية أكبر من المتوفرة';

  @override
  String get showPrintButtonTitle => 'طباعة الفواتير';

  @override
  String get showPrintButtonSubtitle =>
      'إظهار زر الطباعة والطباعة التلقائية عند البيع. أوقفه إذا لم تكن لديك طابعة.';

  @override
  String get shopDetailsItem => 'تفاصيل المحل';

  @override
  String get shopDetailsSubtitle => 'تعديل معلومات المحل والعنوان';

  @override
  String get cashboxItem => 'الصندوق';

  @override
  String get cashboxSubtitle => 'النقد المتوفر والإيداعات والمصروفات';

  @override
  String get cashboxTitle => 'الصندوق';

  @override
  String get cashboxBalanceLabel => 'الرصيد النقدي الحالي';

  @override
  String get todayCashIn => 'وارد اليوم';

  @override
  String get todayCashOut => 'صادر اليوم';

  @override
  String get addDeposit => 'إيداع';

  @override
  String get withdrawMoney => 'سحب';

  @override
  String get addExpense => 'مصروف';

  @override
  String get viewHistory => 'السجل';

  @override
  String get addCashTransaction => 'إضافة حركة';

  @override
  String get selectType => 'اختر النوع';

  @override
  String get recentTransactions => 'أحدث الحركات';

  @override
  String get noCashTransactions => 'لا توجد حركات نقدية بعد';

  @override
  String get cashHistoryTitle => 'سجل الحركات';

  @override
  String get cashInflow => 'وارد';

  @override
  String get cashOutflow => 'صادر';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterToday => 'اليوم';

  @override
  String get filterDateRange => 'فترة';

  @override
  String get filterByType => 'النوع';

  @override
  String get cashDeleteTitle => 'حذف الحركة؟';

  @override
  String get cashDeleteConfirm =>
      'سيتم حذف هذه الحركة النقدية وإعادة حساب الرصيد.';

  @override
  String get cashTransactionAdded => 'تم حفظ الحركة';

  @override
  String get cashTransactionDeleted => 'تم حذف الحركة';

  @override
  String get cashDeleteNotAllowed =>
      'الحركات التلقائية تُحذف بحذف بيعها أو دفعتها';

  @override
  String get cashSaveFailed => 'تعذّر حفظ الحركة';

  @override
  String get cashLoadFailed => 'تعذّر تحميل الصندوق';

  @override
  String get cashTypeOpeningBalance => 'رصيد افتتاحي';

  @override
  String get cashTypeCashSale => 'بيع نقدي';

  @override
  String get cashTypeCustomerDebtPayment => 'سداد دين';

  @override
  String get cashTypeManualDeposit => 'إيداع';

  @override
  String get cashTypeExpense => 'مصروف';

  @override
  String get cashTypePersonalWithdrawal => 'سحب شخصي';

  @override
  String get cashTypePurchasePayment => 'دفعة شراء';

  @override
  String get cashTypeSupplierPayment => 'دفعة مورّد';

  @override
  String get cashTypeManualAdjustment => 'تسوية';

  @override
  String get supportSection => 'الدعم وحول التطبيق';

  @override
  String get contactSupportItem => 'تواصل مع الدعم';

  @override
  String get contactSupportSubtitle => 'احصل على مساعدة في مشكلة أو استفسار';

  @override
  String get rateAppItem => 'قيّم التطبيق';

  @override
  String get rateAppSubtitle => 'شاركنا رأيك بالتطبيق';

  @override
  String get rateAppThanksSubtitle => 'شكراً لتقييمك';

  @override
  String get shareAppItem => 'شارك التطبيق';

  @override
  String get shareAppSubtitle => 'أرسله إلى صاحب محل آخر';

  @override
  String get shareAppMessage =>
      'فواتير — تطبيق نقاط بيع بسيط للمحلات. فواتير ومخزون وديون العملاء وتقارير، كلها دون إنترنت.';

  @override
  String get appVersionItem => 'إصدار التطبيق';

  @override
  String get aboutItem => 'حول فواتير';

  @override
  String get rateTitle => 'قيّم فواتير';

  @override
  String get ratePrompt => 'كيف تجد التطبيق؟';

  @override
  String get rateCommentHint => 'أضف تعليقاً (اختياري)';

  @override
  String get rateSubmit => 'إرسال التقييم';

  @override
  String get rateThanks => 'شكراً لك! تم إرسال تقييمك.';

  @override
  String get rateFailed => 'تعذّر إرسال التقييم. يرجى المحاولة مجدداً.';

  @override
  String get supportSheetTitle => 'كيف تحب أن تتواصل معنا؟';

  @override
  String get supportWhatsApp => 'واتساب';

  @override
  String get supportTelegram => 'تيليجرام';

  @override
  String get supportEmail => 'البريد الإلكتروني';

  @override
  String get supportEmailSubject => 'طلب دعم - تطبيق فواتير';

  @override
  String get supportLaunchFailed => 'تعذّر فتح التطبيق. يرجى تجربة وسيلة أخرى.';

  @override
  String get poweredBy => 'تطوير Evo Tech Systems';

  @override
  String get visitWebsite => 'evotech-sys.com';

  @override
  String get subscriptionActiveChip => 'مفعّل';

  @override
  String get subscriptionInactiveChip => 'غير مفعّل';

  @override
  String get trialChip => 'تجريبي';

  @override
  String get expiresOnLabel => 'ينتهي';

  @override
  String get planLabelShort => 'الباقة';

  @override
  String get hardwareSection => 'الأجهزة';

  @override
  String get appearanceSection => 'المظهر';

  @override
  String get themeModeTitle => 'مظهر التطبيق';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get fontSizeTitle => 'حجم الخط';

  @override
  String get fontSizeSmall => 'صغير';

  @override
  String get fontSizeNormal => 'عادي';

  @override
  String get fontSizeLarge => 'كبير';

  @override
  String get fontSizeExtraLarge => 'كبير جداً';

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
  String get currencyHint => 'ل.س  \$  €  £';

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
  String get priceMustBePositive => 'يجب أن يكون السعر أكبر من صفر';

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
  String unitsTitle(String product) {
    return 'القطع — $product';
  }

  @override
  String unitsSummary(int available, int total) {
    return '$available من $total ما زالت في المخزون';
  }

  @override
  String get unitsAdd => 'إضافة قطعة';

  @override
  String get unitsSerialLabel => 'الرقم التسلسلي';

  @override
  String get unitsSerialHint => 'امسح الرقم أو اكتبه';

  @override
  String get unitsSearchHint => 'بحث بالرقم التسلسلي';

  @override
  String get unitsEmpty =>
      'لا توجد قطع بعد.\nأضف قطعة لكل وحدة موجودة لديك في المخزون.';

  @override
  String get unitsNoMatch => 'لا توجد قطعة بهذا الرقم.';

  @override
  String get serialLabelShort => 'الرقم التسلسلي';

  @override
  String get unitsNoSerial => '(بدون رقم)';

  @override
  String get unitsSetWarranty => 'تحديد تاريخ الكفالة';

  @override
  String get unitsMarkDefective => 'تعليم كمعطّلة';

  @override
  String get unitsRestock => 'إعادة إلى المخزون';

  @override
  String unitsWarrantyUntil(String date) {
    return 'الكفالة حتى $date';
  }

  @override
  String unitsSoldOn(String date) {
    return 'بيعت بتاريخ $date';
  }

  @override
  String get unitStatusInStock => 'في المخزون';

  @override
  String get unitStatusSold => 'مباعة';

  @override
  String get unitStatusReturned => 'مرتجعة';

  @override
  String get unitStatusDefective => 'معطّلة';

  @override
  String get unitsAdded => 'تمت إضافة القطعة';

  @override
  String get unitsSaved => 'تم الحفظ';

  @override
  String get unitsDeleted => 'تم حذف القطعة';

  @override
  String get unitsLoadFailed => 'تعذّر تحميل القائمة.';

  @override
  String get unitsSaveFailed => 'تعذّر الحفظ. حاول مرة أخرى.';

  @override
  String get unitsDuplicateSerial =>
      'هذا الرقم مسجّل مسبقاً. تأكّد أنك لم تمسح القطعة نفسها مرتين.';

  @override
  String get unitsDeleteBlockedSold =>
      'هذه القطعة مباعة ولا يمكن حذفها — سجلّها يربط الرقم التسلسلي بفاتورته.';

  @override
  String get unitsDeleteTitle => 'حذف هذه القطعة؟';

  @override
  String get unitsDeleteBody =>
      'سيتم حذف القطعة من المخزون. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get productSerialized => 'لكل قطعة رقم تسلسلي خاص';

  @override
  String get productSerializedHint =>
      'فعّلها للبضائع التي تُتابَع قطعة قطعة — الهواتف، الأجهزة، العدّة، الذهب. عندها يُحتسب المخزون من القطع التي تضيفها.';

  @override
  String get productUnitsAction => 'القطع';

  @override
  String get stockFromUnitsHint =>
      'يُحتسب من القطع التي تضيفها — افتح «القطع» لتعديله.';

  @override
  String unitNotAvailableError(String serial) {
    return 'هذه القطعة (الرقم التسلسلي $serial) لم تعد في المخزون — تم بيعها مسبقاً.';
  }

  @override
  String get unknownBarcodeTitle => 'باركود غير مسجّل';

  @override
  String unknownBarcodeMessage(String barcode) {
    return 'هذا الباركود غير موجود: $barcode\nهل تريد إضافته كمنتج جديد؟';
  }

  @override
  String get unknownBarcodeAdd => 'إضافة منتج جديد';

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

  @override
  String get licenseChecking => 'جارٍ التحقق من اشتراكك…';

  @override
  String get licenseErrorNetwork =>
      'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.';

  @override
  String get licenseErrorServer =>
      'تعذّر التحقق من اشتراكك حالياً. حاول مرة أخرى.';

  @override
  String get licenseErrorUnexpected => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get activationTitle => 'تفعيل فواتير';

  @override
  String get activationSubtitle =>
      'أدخل بياناتك للتحقق من اشتراكك، أو اختر باقة للبدء.';

  @override
  String get activationNameLabel => 'الاسم الكامل';

  @override
  String get activationPhoneLabel => 'رقم الهاتف';

  @override
  String get activationCheckButton => 'التحقق من التفعيل';

  @override
  String get activationViewPlans => 'عرض باقات الاشتراك';

  @override
  String get licenseExpiredTitle => 'انتهى الاشتراك';

  @override
  String get licenseExpiredSubtitle => 'جدّد اشتراكك لمواصلة استخدام التطبيق.';

  @override
  String licenseExpiresOn(String date) {
    return 'صالح حتى $date';
  }

  @override
  String get plansTitle => 'باقات الاشتراك';

  @override
  String get plansEmpty => 'لا توجد باقات متاحة حالياً.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get planRecommended => 'الأفضل قيمة';

  @override
  String planDurationMonths(int count) {
    return '$count شهر';
  }

  @override
  String get planSubscribe => 'اشترك';

  @override
  String get planRequestSent => 'تم إرسال طلبك. سنفعّل جهازك قريباً.';

  @override
  String get contactMethodTitle => 'تواصل معنا لإتمام اشتراكك';

  @override
  String get contactWhatsApp => 'واتساب';

  @override
  String get contactTelegram => 'تيليجرام';

  @override
  String get contactEmail => 'البريد الإلكتروني';

  @override
  String get contactEmailSubject => 'طلب اشتراك فواتير';

  @override
  String get updateAvailableTitle => 'يتوفر تحديث جديد';

  @override
  String get updateDownload => 'تحميل التحديث';

  @override
  String get updateAvailableGeneric => 'يتوفر إصدار جديد من التطبيق.';

  @override
  String get updateLater => 'لاحقاً';

  @override
  String get verifyRequiredTitle => 'مطلوب التحقق من الاشتراك';

  @override
  String get verifyOfflineMessage =>
      'لم يتمكن التطبيق من الاتصال بالخادم منذ فترة. يرجى الاتصال بالإنترنت ثم الضغط على إعادة المحاولة للمتابعة.';

  @override
  String get verifyTamperMessage =>
      'تم اكتشاف تغيير في تاريخ ووقت الجهاز. يرجى تصحيح التاريخ والوقت والاتصال بالإنترنت ثم الضغط على إعادة المحاولة.';

  @override
  String get verifyDataSafe => 'جميع بياناتك محفوظة على هذا الجهاز.';

  @override
  String get verifyChecking => 'جارٍ التحقق…';

  @override
  String offlineWarnBanner(int days) {
    return 'لا يوجد اتصال بالخادم منذ $days يوم — اتصل بالإنترنت للتحقق';
  }

  @override
  String get trialExpiredNotice =>
      'انتهت الفترة التجريبية. اختر باقة لتفعيل الاشتراك والمتابعة — جميع بياناتك محفوظة.';

  @override
  String get subscriptionExpiredNotice =>
      'انتهى اشتراكك. اختر باقة للتجديد والمتابعة — جميع بياناتك محفوظة.';

  @override
  String get checkForUpdatesHint => 'اضغط للتحقق من وجود تحديثات';

  @override
  String get updateUpToDate => 'أنت على أحدث إصدار';

  @override
  String get updateCheckFailed =>
      'تعذّر التحقق من التحديثات. تحقق من اتصالك بالإنترنت.';

  @override
  String contactMessage(
      String plan, String name, String phone, String deviceId) {
    return 'مرحباً،\nأرغب في الاشتراك في تطبيق فواتير.\nالباقة: $plan\nالاسم: $name\nرقم الهاتف: $phone\nمعرّف الجهاز: $deviceId';
  }

  @override
  String get contactMessagePreview => 'الرسالة التي سنرسلها';

  @override
  String get contactLaunchFailed =>
      'تعذّر فتح التطبيق. انسخ الرسالة وأرسلها لنا يدوياً.';

  @override
  String get customersTitle => 'العملاء';

  @override
  String get addCustomer => 'إضافة عميل';

  @override
  String get editCustomer => 'تعديل العميل';

  @override
  String get customerNameLabel => 'الاسم';

  @override
  String get customerPhoneLabel => 'الهاتف (اختياري)';

  @override
  String get customerNoteLabel => 'ملاحظة (اختياري)';

  @override
  String get customerAdded => 'تمت إضافة العميل';

  @override
  String get customerUpdated => 'تم تحديث العميل';

  @override
  String get customerDeleted => 'تم حذف العميل';

  @override
  String get customerDeleteBlocked => 'لا يمكن حذف عميل له حركات في الدفتر.';

  @override
  String get customerSaveFailed => 'تعذّر الحفظ. حاول مرة أخرى.';

  @override
  String get customersLoadFailed => 'تعذّر تحميل العملاء.';

  @override
  String get noCustomers => 'لا يوجد عملاء بعد';

  @override
  String get noCustomersHint => 'أضف عميلاً لتتبع البيع الآجل والدفعات.';

  @override
  String get selectCustomer => 'اختر العميل';

  @override
  String get addNewCustomer => 'إضافة عميل جديد';

  @override
  String get searchCustomerHint => 'ابحث عن عميل';

  @override
  String get noMatchingCustomers => 'لا يوجد عملاء مطابقون';

  @override
  String get duplicateCustomerName => 'يوجد عميل بهذا الاسم بالفعل';

  @override
  String andMoreTypeToSearch(int count) {
    return '+$count آخرين — اكتب للبحث';
  }

  @override
  String get balanceSettled => 'مسدّد';

  @override
  String balanceOwed(String amount) {
    return 'عليه $amount';
  }

  @override
  String balanceCredit(String amount) {
    return 'له $amount';
  }

  @override
  String get balanceOwedLabel => 'عليه لك';

  @override
  String get balanceCreditLabel => 'له عليك';

  @override
  String get recordPayment => 'تسجيل دفعة';

  @override
  String get addDebt => 'إضافة دين';

  @override
  String get noLedgerEntries => 'لا توجد حركات بعد';

  @override
  String get entryPayment => 'دفعة';

  @override
  String get entryDebt => 'دين';

  @override
  String get creditSaleTag => 'بيع آجل';

  @override
  String get deleteEntryTitle => 'حذف الحركة';

  @override
  String get deleteEntryConfirm => 'حذف هذه الحركة من الدفتر؟';

  @override
  String get deleteCustomerTitle => 'حذف العميل';

  @override
  String get deleteCustomerConfirm =>
      'حذف هذا العميل؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get debtAdded => 'تمت إضافة الدين';

  @override
  String get paymentRecorded => 'تم تسجيل الدفعة';

  @override
  String get entryDeleted => 'تم حذف الحركة';

  @override
  String get ledgerSaveFailed => 'تعذّر الحفظ. حاول مرة أخرى.';

  @override
  String get ledgerLoadFailed => 'تعذّر تحميل الحساب.';

  @override
  String get amountLabel => 'المبلغ';

  @override
  String get noteOptional => 'ملاحظة (اختياري)';

  @override
  String get amountMustBePositive => 'أدخل مبلغاً أكبر من صفر';

  @override
  String get sellOnCredit => 'بيع آجل';

  @override
  String get cashSale => 'نقداً';

  @override
  String get chooseCustomer => 'اختر العميل';

  @override
  String creditToLabel(String name) {
    return 'آجل — $name';
  }

  @override
  String get shareStatement => 'مشاركة كشف الحساب';

  @override
  String get printStatement => 'طباعة كشف الحساب';

  @override
  String get statementPrinted => 'تمت طباعة كشف الحساب';

  @override
  String statementHeader(String shop) {
    return 'كشف حساب — $shop';
  }

  @override
  String get statementDate => 'التاريخ';

  @override
  String get statementTotalDebts => 'إجمالي الديون';

  @override
  String get statementTotalPaid => 'إجمالي المدفوع';

  @override
  String get statementBalance => 'الرصيد';

  @override
  String get accountSection => 'الحساب';

  @override
  String get accountInfoSection => 'معلومات الحساب';

  @override
  String get notSet => 'لم يتم التعيين';

  @override
  String get editAccountTitle => 'تعديل بيانات الحساب';

  @override
  String get agentSavedSynced => 'تم الحفظ ومزامنة السيرفر';

  @override
  String get agentSavedLocal => 'تم الحفظ محلياً — تعذّر الاتصال بالسيرفر';

  @override
  String get subscriptionItem => 'الاشتراك';

  @override
  String get subscriptionSubtitle => 'عرض الحالة وتجديد الباقة';

  @override
  String get subscriptionTitle => 'الاشتراك';

  @override
  String get statusActive => 'نشط';

  @override
  String get statusTrial => 'تجريبي';

  @override
  String get statusExpired => 'منتهي';

  @override
  String get statusInactive => 'غير مفعّل';

  @override
  String daysRemaining(int days) {
    return '$days يوم متبقٍ';
  }

  @override
  String lastChecked(String date) {
    return 'آخر تحقق: $date';
  }

  @override
  String get neverChecked => 'لم يتم';

  @override
  String get refreshStatus => 'تحديث الحالة';

  @override
  String get renewSubscription => 'تجديد / تغيير الباقة';

  @override
  String get deviceIdLabel => 'معرّف الجهاز';

  @override
  String get deviceIdHint => 'أرسل هذا المعرّف للدعم لتفعيل جهازك.';

  @override
  String get copy => 'نسخ';

  @override
  String get copied => 'تم النسخ';

  @override
  String get subscriptionActivatedBanner => 'تم تفعيل اشتراكك';

  @override
  String get trialBannerNoDate => 'نسخة تجريبية';

  @override
  String trialBannerWithDate(int days, String date) {
    return 'نسخة تجريبية — باقٍ $days يوم (حتى $date)';
  }

  @override
  String trialBanner(int days) {
    return 'نسخة تجريبية — باقٍ $days يوم';
  }

  @override
  String get trialUpgrade => 'ترقية';

  @override
  String get backupTitle => 'النسخ الاحتياطي والاستعادة';

  @override
  String get backupItem => 'النسخ الاحتياطي والاستعادة';

  @override
  String get backupSubtitle => 'احمِ بياناتك عبر Google Drive';

  @override
  String get backupSignInPrompt =>
      'سجّل الدخول بحساب Google الخاص بك للاحتفاظ بنسخة آمنة من جميع بياناتك (المبيعات، المنتجات، العملاء، الديون، الصندوق) في Google Drive الخاص بك. إذا فُقد هاتفك أو تعطّل، يمكنك استعادة كل شيء على جهاز جديد.';

  @override
  String backupAccountHint(String account) {
    return 'نسخك الاحتياطية السابقة موجودة على الحساب $account';
  }

  @override
  String get backupSignInButton => 'تسجيل الدخول عبر Google';

  @override
  String get backupSignOut => 'تسجيل الخروج';

  @override
  String get backupAccountLabel => 'الحساب المسجّل';

  @override
  String get backupNowButton => 'أنشئ نسخة الآن';

  @override
  String get backupAutoTitle => 'نسخ احتياطي تلقائي يومي';

  @override
  String get backupAutoSubtitle =>
      'يتم النسخ مرة يومياً عند فتح التطبيق ووجود اتصال بالإنترنت.';

  @override
  String get backupExportButton => 'تصدير نسخة للمشاركة';

  @override
  String get backupLastLabel => 'آخر نسخة احتياطية';

  @override
  String get backupNever => 'لا توجد نسخة احتياطية بعد — بياناتك غير محمية';

  @override
  String get backupListTitle => 'نسخك الاحتياطية';

  @override
  String get backupListEmpty => 'لا توجد نسخ احتياطية في هذا الحساب';

  @override
  String get backupRestore => 'استعادة';

  @override
  String get backupThisDevice => 'هذا الجهاز';

  @override
  String get backupRestoreConfirmTitle => 'استعادة هذه النسخة؟';

  @override
  String get backupRestoreConfirmBody =>
      'سيؤدي هذا إلى استبدال جميع البيانات الحالية على هذا الجهاز بالنسخة المحددة. لا يمكن التراجع عن ذلك. سيُغلق التطبيق لتعيد فتحه من جديد.';

  @override
  String get backupRestartTitle => 'اكتملت الاستعادة';

  @override
  String get backupRestartBody =>
      'تمت استعادة بياناتك. من فضلك أعد فتح التطبيق للإنهاء.';

  @override
  String get backupRestartAction => 'إغلاق التطبيق';

  @override
  String get backupRestoreFailedTitle => 'لم تكتمل الاستعادة';

  @override
  String get backupRestoreFailedBody =>
      'لم يتم تغيير بياناتك — هي سليمة تماماً كما كانت. لكن يجب إعادة فتح التطبيق ليعمل من جديد.';

  @override
  String get backupSuccessBackedUp => 'تم إنشاء النسخة الاحتياطية بنجاح';

  @override
  String get backupSuccessExported => 'النسخة جاهزة — اختر مكان المشاركة';

  @override
  String get backupErrorNetwork =>
      'لا يوجد اتصال بالإنترنت. اتصل وحاول مرة أخرى.';

  @override
  String get backupErrorServer => 'خطأ في Google Drive. حاول مرة أخرى.';

  @override
  String get backupErrorSignIn => 'تم إلغاء تسجيل الدخول أو لم يكتمل.';

  @override
  String get backupErrorIncompatibleNew =>
      'أُنشئت هذه النسخة بإصدار أحدث من التطبيق. رجاءً حدّث التطبيق قبل الاستعادة.';

  @override
  String get backupErrorCorrupt =>
      'ملف النسخة الاحتياطية تالف ولا يمكن استعادته.';

  @override
  String get backupErrorUnknown => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get backupBusyBackingUp => 'جارٍ النسخ…';

  @override
  String get backupBusyRestoring => 'جارٍ الاستعادة…';

  @override
  String get priceCurrencyLabel => 'عملة السعر';

  @override
  String get currencySp => 'ل.س';

  @override
  String get currencyUsd => 'دولار';

  @override
  String get currencySettingsItem => 'العملة وسعر الصرف';

  @override
  String get currencySettingsSubtitle =>
      'حدّد سعر تحويل الدولار إلى الليرة للمنتجات المسعّرة بالدولار';

  @override
  String get currencySettingsTitle => 'العملة وسعر الصرف';

  @override
  String get currencySettingsNote =>
      'الليرة السورية هي عملتك الأساسية. المنتجات المسعّرة بالدولار تُحوَّل إلى الليرة بهذا السعر عند البيع. تغيير السعر يؤثّر على المبيعات الجديدة فقط — الفواتير السابقة تحتفظ بسعرها الأصلي.';

  @override
  String get exchangeRateLabel => 'الليرة مقابل ١ دولار';

  @override
  String get exchangeRateHint => 'مثال: ١٥٠٠٠';

  @override
  String get exchangeRateInvalid => 'أدخل سعراً أكبر من صفر';

  @override
  String get exchangeRateSaved => 'تم حفظ سعر الصرف';

  @override
  String get exchangeRateNever => 'غير محدّد بعد';

  @override
  String get setExchangeRateShort => 'سعر الدولار';

  @override
  String exchangeRateUpdatedAt(String date) {
    return 'آخر تحديث: $date';
  }

  @override
  String get exchangeRateMissingError =>
      'حدّد سعر صرف الدولار من الإعدادات ← العملة قبل بيع منتج مسعّر بالدولار.';

  @override
  String get discountTitle => 'خصم';

  @override
  String get discountPercent => 'نسبة';

  @override
  String get discountAmount => 'مبلغ';

  @override
  String get discountValueHint => 'القيمة';

  @override
  String get discountApply => 'تطبيق';

  @override
  String get discountRemove => 'إزالة';

  @override
  String get addDiscountAction => 'خصم';

  @override
  String get discountLabel => 'الخصم';

  @override
  String get subtotalLabel => 'المجموع الفرعي';

  @override
  String get cartDiscountLabel => 'خصم على الفاتورة';

  @override
  String get shareAction => 'مشاركة';

  @override
  String get shareFailed => 'تعذّر تجهيز المشاركة — حاول مرة أخرى';

  @override
  String get estimatedProfit => 'الربح التقديري';

  @override
  String get openingBalance => 'رصيد أول المدة';

  @override
  String get closingBalance => 'رصيد آخر المدة';

  @override
  String get cashboxDailySummaryTitle => 'ملخص الصندوق اليومي';

  @override
  String get salesSummaryTitle => 'ملخص المبيعات';

  @override
  String get reportPeriodLabel => 'الفترة';

  @override
  String get receiptThankYou => 'شكراً لتعاملكم معنا';

  @override
  String get reportsTab => 'التقارير';

  @override
  String get dashboardTab => 'لوحة المعلومات';

  @override
  String get salesTabLabel => 'المبيعات';

  @override
  String get filterLast7Days => 'آخر ٧ أيام';

  @override
  String get filterLast30Days => 'آخر ٣٠ يوماً';

  @override
  String get revenueLabel => 'الإيرادات';

  @override
  String get outstandingDebtsLabel => 'الديون المستحقة';

  @override
  String get inventoryValueLabel => 'قيمة المخزون';

  @override
  String get salesTrendTitle => 'اتجاه المبيعات';

  @override
  String get topProductsTitle => 'أفضل المنتجات';

  @override
  String get cashFlowTitle => 'التدفق النقدي';

  @override
  String get lowStockTitle => 'مخزون منخفض';

  @override
  String get topDebtorsTitle => 'أكبر المدينين';

  @override
  String get metricQuantity => 'الكمية';

  @override
  String get metricProfit => 'الربح';

  @override
  String get cashInLabel => 'الوارد';

  @override
  String get cashOutLabel => 'الصادر';

  @override
  String get expensesLabel => 'المصروفات';

  @override
  String get withdrawalsLabel => 'السحوبات';

  @override
  String get dashboardNoData => 'لا توجد مبيعات في هذه الفترة بعد';

  @override
  String get dashboardLoadFailed => 'تعذّر تحميل اللوحة';

  @override
  String unitsSuffix(String count) {
    return '$count مبيعاً';
  }

  @override
  String get scanBarcodeTitle => 'مسح الباركود';

  @override
  String get alignBarcodeHint => 'وجّه الباركود داخل الإطار';

  @override
  String get productFieldsItem => 'حقول المنتج';

  @override
  String get productFieldsSubtitle => 'معلومات مخصّصة تُحفظ لكل منتج';

  @override
  String get productFieldsTitle => 'حقول المنتج';

  @override
  String get productFieldsEmpty => 'لا توجد حقول مخصّصة بعد';

  @override
  String get productFieldsEmptyHint =>
      'أضف حقولاً مثل اللون أو السعة، أو ابدأ من قالب جاهز لنوع متجرك.';

  @override
  String get addFieldBtn => 'إضافة حقل';

  @override
  String get useTemplateBtn => 'ابدأ من قالب';

  @override
  String get chooseBusinessType => 'اختر نوع نشاطك';

  @override
  String get templateSeedNote =>
      'يضيف حقولاً مقترحة. يمكنك تعديلها أو حذفها في أي وقت.';

  @override
  String get fieldNameLabel => 'اسم الحقل';

  @override
  String get fieldNameHint => 'مثال: اللون، السعة، الكفالة';

  @override
  String get fieldTypeLabel => 'نوع الحقل';

  @override
  String get fieldUnitLabel => 'الوحدة (اختياري)';

  @override
  String get fieldUnitHint => 'مثال: GB، ml، V';

  @override
  String get fieldOptionsLabel => 'الخيارات';

  @override
  String get fieldOptionsHint => 'افصل الخيارات بفواصل';

  @override
  String get fieldRequiredLabel => 'إلزامي';

  @override
  String get fieldShowInListLabel => 'إظهار في قائمة المنتجات';

  @override
  String get fieldShowOnReceiptLabel => 'إظهار على الفاتورة';

  @override
  String get fieldArchiveAction => 'أرشفة';

  @override
  String get fieldUnarchiveAction => 'استعادة';

  @override
  String get fieldDeleteAction => 'حذف';

  @override
  String get fieldArchivedBadge => 'مؤرشف';

  @override
  String get attrTypeText => 'نص';

  @override
  String get attrTypeNumber => 'رقم';

  @override
  String get attrTypeSelect => 'قائمة خيارات';

  @override
  String get attrTypeBoolean => 'نعم / لا';

  @override
  String get attrTypeDate => 'تاريخ';

  @override
  String get templateAppliedMsg => 'تمت إضافة الحقول';

  @override
  String get showArchivedFields => 'عرض المؤرشفة';

  @override
  String get filterProductsTitle => 'تصفية المنتجات';

  @override
  String get clearFiltersBtn => 'مسح الكل';

  @override
  String get noFilterableFields =>
      'لا توجد حقول قابلة للتصفية. أضف حقل قائمة خيارات لتصفّي حسبه.';

  @override
  String get salesByFieldTitle => 'المبيعات حسب الحقل';

  @override
  String get salesByFieldHint => 'اختر حقلاً لتفصيل المبيعات حسب قيمه.';

  @override
  String get reportFieldNone => 'إيقاف';

  @override
  String get printLabelTitle => 'طباعة ملصق';

  @override
  String get printLabelAction => 'طباعة';

  @override
  String get labelCopies => 'عدد النسخ';

  @override
  String get labelBarcode => 'باركود';

  @override
  String get labelQr => 'QR';

  @override
  String get labelPrinted => 'تم إرسال الملصق إلى الطابعة';

  @override
  String get labelPrintFailed => 'تعذّرت الطباعة — تحقّق من اتصال الطابعة';

  @override
  String get unknownBarcodeSearch => 'بحث';

  @override
  String get productNameExistsError => 'يوجد منتج بهذا الاسم بالفعل';

  @override
  String get syncItem => 'الأجهزة والمزامنة';

  @override
  String get syncSubtitle => 'شارك هذا المحل بين هاتفين';

  @override
  String get syncTitle => 'الأجهزة والمزامنة';

  @override
  String get syncPitchTitle => 'استخدم محلّك على أكثر من هاتف';

  @override
  String get syncPitchBody =>
      'المبيعات والمنتجات والزبائن والصندوق تبقى نفسها على كل هاتف. كل هاتف يعمل بدون إنترنت ويتحدّث عند عودة الاتصال.';

  @override
  String get syncEnableAction => 'تفعيل للمحل';

  @override
  String get syncEnableHint => 'اختر هذا على الهاتف الذي يحتوي بياناتك.';

  @override
  String get syncJoinAction => 'الانضمام إلى محل';

  @override
  String get syncJoinHint =>
      'اختر هذا على الهاتف الثاني، ثم امسح الرمز الظاهر على الهاتف الأول.';

  @override
  String get syncStatusOwner => 'الهاتف الرئيسي';

  @override
  String get syncStatusMember => 'هاتف مرتبط';

  @override
  String syncDevicesUsed(int allowance) {
    return 'عدد الأجهزة المسموح: $allowance';
  }

  @override
  String syncLastAt(String when) {
    return 'آخر مزامنة: $when';
  }

  @override
  String get syncNever => 'لم تتم المزامنة بعد';

  @override
  String get syncNowAction => 'مزامنة الآن';

  @override
  String get syncUpToDate => 'كل شيء محدّث';

  @override
  String syncMovedCounts(int sent, int received) {
    return 'أُرسل $sent، ووصل $received';
  }

  @override
  String syncPendingRejected(int count) {
    return 'تعذّر إرسال $count تغييرات — ستتم إعادة المحاولة';
  }

  @override
  String get syncAddDeviceAction => 'إضافة هاتف';

  @override
  String get syncJoinCodeTitle => 'امسح الرمز على الهاتف الآخر';

  @override
  String syncJoinCodeExpires(int minutes) {
    return 'صالح لمدة $minutes دقيقة';
  }

  @override
  String get syncJoinCodeExpired => 'انتهت صلاحية الرمز — أنشئ رمزاً جديداً';

  @override
  String get syncJoinCodeManual => 'أو اكتب هذا الرمز';

  @override
  String get syncJoinCodeCopied => 'تم نسخ الرمز';

  @override
  String get syncJoinCodeDone => 'تم';

  @override
  String get syncEnterCodeTitle => 'الانضمام إلى محل';

  @override
  String get syncEnterCodeLabel => 'الرمز من الهاتف الآخر';

  @override
  String get syncEnterCodeScan => 'مسح';

  @override
  String get syncEnterCodeConfirm => 'انضمام';

  @override
  String get syncLeaveAction => 'إلغاء ربط هذا الهاتف';

  @override
  String get syncLeaveTitle => 'إلغاء ربط هذا الهاتف؟';

  @override
  String get syncLeaveBody =>
      'يحتفظ الهاتف بكل بياناته لكنه يتوقف عن المشاركة مع الأجهزة الأخرى. لا يُحذف أي شيء.';

  @override
  String get syncLeaveConfirm => 'إلغاء الربط';

  @override
  String get syncEnabledMessage => 'تم تفعيل المزامنة للمحل';

  @override
  String get syncJoinedMessage => 'تم ربط هذا الهاتف';

  @override
  String get syncLeftMessage => 'لم يعد هذا الهاتف مرتبطاً';

  @override
  String get syncErrorSubscription => 'اشتراكك لا يشمل أجهزة إضافية';

  @override
  String get syncErrorAllowance => 'استخدمت كل الأجهزة المسموح بها في خطتك';

  @override
  String get syncErrorJoinToken => 'الرمز غير صحيح أو مستخدم أو منتهي الصلاحية';

  @override
  String get syncErrorFallbackDevice =>
      'لا يمكن تمييز هذا الهاتف بشكل موثوق، لذا لا يمكن ربطه';

  @override
  String get syncErrorOffline => 'لا يوجد اتصال — ستتم إعادة المحاولة تلقائياً';

  @override
  String get syncErrorServer => 'حدث خطأ. حاول مرة أخرى';

  @override
  String get syncCopyCode => 'نسخ';

  @override
  String get syncStepSyncing => 'جارٍ التحديث مع الهواتف الأخرى…';

  @override
  String get syncStepSnapshotting => 'جارٍ تجهيز نسخة من المحل…';

  @override
  String get syncStepUploading => 'جارٍ إرسال المحل إلى الهاتف الجديد…';

  @override
  String get syncJoinCodePreferScan => 'المسح أأمن من كتابة الرمز.';

  @override
  String get syncRestartTitle => 'المحل الآن على هذا الهاتف';

  @override
  String get syncRestartBody =>
      'أصبحت نسخة المحل على هذا الهاتف، ويلزم فتح التطبيق من جديد لاستخدامها. أغلق التطبيق ثم شغّله مرة أخرى.';

  @override
  String get syncRestartConfirm => 'إغلاق التطبيق';
}
