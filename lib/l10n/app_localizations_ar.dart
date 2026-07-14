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
  String get updateLater => 'لاحقاً';

  @override
  String contactMessage(String plan) {
    return 'مرحباً، أرغب في الاشتراك في باقة $plan لتطبيق فواتير.';
  }

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
  String get backupTitle => 'النسخ الاحتياطي والاستعادة';

  @override
  String get backupItem => 'النسخ الاحتياطي والاستعادة';

  @override
  String get backupSubtitle => 'احمِ بياناتك عبر Google Drive';

  @override
  String get backupSignInPrompt =>
      'سجّل الدخول بحساب Google الخاص بك للاحتفاظ بنسخة آمنة من جميع بياناتك (المبيعات، المنتجات، العملاء، الديون، الصندوق) في Google Drive الخاص بك. إذا فُقد هاتفك أو تعطّل، يمكنك استعادة كل شيء على جهاز جديد.';

  @override
  String get backupSignInButton => 'تسجيل الدخول عبر Google';

  @override
  String get backupSignOut => 'تسجيل الخروج';

  @override
  String get backupAccountLabel => 'الحساب المسجّل';

  @override
  String get backupNowButton => 'أنشئ نسخة الآن';

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
}
