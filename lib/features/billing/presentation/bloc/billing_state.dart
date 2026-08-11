part of 'billing_bloc.dart';

/// A localizable billing error. The BLoC sets the case; pages map it to a
/// translated string — no user-facing English lives in the BLoC.
enum BillingError {
  productNotFound,
  saveFailed,
  printerUnavailable,
  printFailed,
  emptyCart,
  exchangeRateMissing,

  /// Strict inventory is on and the cart sells a tracked item past its on-hand
  /// count. Only reachable when the owner enabled the toggle.
  insufficientStock,

  /// A scanned IMEI/serial matched a unit that is no longer sellable — already
  /// sold, returned or defective (Plan 012). Distinct from [productNotFound]
  /// because the answer is completely different: the serial IS known, so
  /// "product not found" would send the cashier hunting a shelf for a phone
  /// that was sold last week.
  unitNotAvailable,
}

/// Sentinel so [BillingState.copyWith] can distinguish "leave the nullable rate
/// unchanged" from "set it to null" (an unset rate is a real state).
const Object _unset = Object();

class BillingState extends Equatable {
  final List<CartItem> cartItems;
  final BillingError? error;

  /// The barcode that wasn't found — only set for [BillingError.productNotFound]
  /// so the UI can name it in the message.
  final String? errorBarcode;
  final bool isPrinting;
  final bool printSuccess;
  final bool isSaving;
  final bool saleConfirmed;
  final String? savedInvoiceId;
  final List<String> lowStockWarnings;

  /// Set when a measured product (e.g. sold by weight) is scanned and needs the
  /// cashier to enter a weight/amount before it's added. The POS page listens
  /// for this, opens the entry dialog, then clears it. Null otherwise.
  final Product? measuredPrompt;

  /// Set for one transition when a *stock-tracked* product that has run out is
  /// scanned (Plan 011 #8). The item is still added to the cart (overselling is
  /// allowed by default), but the POS shows a red "out of stock" notice so the
  /// shopkeeper knows the item is finished instead of hunting the shelf. The
  /// POS page consumes it and clears it. Null otherwise.
  final Product? outOfStockScan;

  /// Set for one transition when a scanned barcode matches **more than one**
  /// product (Plan 015 Case A — the same packet sold at two prices from two
  /// piles). The POS opens a chooser, adds the picked product, then clears it.
  /// Empty otherwise.
  ///
  /// The BLoC never opens UI, so this follows `measuredPrompt`'s shape exactly:
  /// state carries the question, the page asks it.
  final List<Product> barcodeChoices;

  /// Current USD→SP rate (SP per 1 USD), or null if the owner hasn't set one.
  /// Used to price USD products into SP as they enter the cart.
  final double? exchangeRate;

  /// When [exchangeRate] was last set — drives a "your rate is stale" hint.
  final DateTime? rateUpdatedAt;

  /// Manual whole-cart discount in SP, applied on top of any per-line discounts.
  /// Clamped to the subtotal via [effectiveInvoiceDiscount]. 0 = none.
  final double invoiceDiscount;

  /// When true, the checkout refuses to sell a tracked item past its on-hand
  /// count (Settings → Inventory). Off by default — stock is optional, so
  /// overselling stays allowed unless the owner opts in.
  final bool blockOversell;

  /// When true (the default), the checkout shows its print button and auto-prints
  /// a confirmed sale; when false the shop has no printer, so both are skipped
  /// (Plan 011 #6). Loaded by [LoadPrintSettingsEvent] at startup and on toggle.
  final bool printEnabled;

  const BillingState({
    this.cartItems = const [],
    this.error,
    this.errorBarcode,
    this.isPrinting = false,
    this.printSuccess = false,
    this.isSaving = false,
    this.saleConfirmed = false,
    this.savedInvoiceId,
    this.lowStockWarnings = const [],
    this.measuredPrompt,
    this.outOfStockScan,
    this.barcodeChoices = const [],
    this.exchangeRate,
    this.rateUpdatedAt,
    this.invoiceDiscount = 0,
    this.blockOversell = false,
    this.printEnabled = true,
  });

  /// Sum of the (line-discounted) line totals, before the whole-cart discount.
  double get subtotal => cartItems.fold(0, (sum, item) => sum + item.total);

  /// Whole-cart discount actually applied — never negative, never more than
  /// [subtotal].
  double get effectiveInvoiceDiscount => invoiceDiscount <= 0
      ? 0
      : (invoiceDiscount > subtotal ? subtotal : invoiceDiscount);

  /// Grand total in SP: subtotal minus the whole-cart discount.
  double get totalAmount => subtotal - effectiveInvoiceDiscount;

  /// Total of all discounts on this sale (line + whole-cart), for display.
  double get totalDiscount =>
      cartItems.fold<double>(0, (s, i) => s + i.effectiveDiscount) +
      effectiveInvoiceDiscount;

  /// True when any cart line is a USD product that couldn't be converted (no
  /// rate set) — the checkout guard uses this to block the sale.
  bool get hasUnpricedItems => cartItems.any((i) => i.isUnpriced);

  /// Names of cart lines selling more than the product's on-hand quantity — the
  /// strict-inventory **block** list.
  ///
  /// Unlike [lowStockWarnings] (a soft amber heads-up that deliberately skips
  /// untracked loose items so they don't nag), this counts **every** product:
  /// turning strict inventory on means "enforce stock for everything", so a
  /// sold-out item (on-hand 0) is blocked too — which is exactly what the toggle
  /// promises. `qty > onHand`, so selling the last unit down to 0 is fine; only
  /// going *past* on-hand is blocked.
  List<String> get oversoldItems => cartItems
      .where((i) => i.quantity > i.product.quantity)
      .map((i) => i.product.name)
      .toList();

  /// True when strict inventory is on AND the cart would sell past on-hand. The
  /// checkout uses this to turn the warning into a hard block and disable
  /// Confirm; [_onConfirmSale] refuses the sale.
  bool get isStockBlocked => blockOversell && oversoldItems.isNotEmpty;

  BillingState copyWith({
    List<CartItem>? cartItems,
    BillingError? error,
    String? errorBarcode,
    bool clearError = false,
    bool? isPrinting,
    bool? printSuccess,
    bool? isSaving,
    bool? saleConfirmed,
    String? savedInvoiceId,
    bool clearSale = false,
    List<String>? lowStockWarnings,
    Product? measuredPrompt,
    bool clearMeasuredPrompt = false,
    Product? outOfStockScan,
    bool clearOutOfStockScan = false,
    List<Product>? barcodeChoices,
    bool clearBarcodeChoices = false,
    Object? exchangeRate = _unset,
    Object? rateUpdatedAt = _unset,
    double? invoiceDiscount,
    bool? blockOversell,
    bool? printEnabled,
  }) {
    return BillingState(
      cartItems: cartItems ?? this.cartItems,
      error: clearError ? null : (error ?? this.error),
      errorBarcode: clearError ? null : (errorBarcode ?? this.errorBarcode),
      isPrinting: isPrinting ?? this.isPrinting,
      printSuccess: printSuccess ?? this.printSuccess,
      isSaving: isSaving ?? this.isSaving,
      saleConfirmed: clearSale ? false : (saleConfirmed ?? this.saleConfirmed),
      savedInvoiceId:
          clearSale ? null : (savedInvoiceId ?? this.savedInvoiceId),
      lowStockWarnings: lowStockWarnings ?? this.lowStockWarnings,
      measuredPrompt:
          clearMeasuredPrompt ? null : (measuredPrompt ?? this.measuredPrompt),
      outOfStockScan: clearOutOfStockScan
          ? null
          : (outOfStockScan ?? this.outOfStockScan),
      barcodeChoices: clearBarcodeChoices
          ? const []
          : (barcodeChoices ?? this.barcodeChoices),
      exchangeRate: identical(exchangeRate, _unset)
          ? this.exchangeRate
          : exchangeRate as double?,
      rateUpdatedAt: identical(rateUpdatedAt, _unset)
          ? this.rateUpdatedAt
          : rateUpdatedAt as DateTime?,
      invoiceDiscount: invoiceDiscount ?? this.invoiceDiscount,
      blockOversell: blockOversell ?? this.blockOversell,
      printEnabled: printEnabled ?? this.printEnabled,
    );
  }

  @override
  List<Object?> get props => [
        cartItems,
        error,
        errorBarcode,
        isPrinting,
        printSuccess,
        isSaving,
        saleConfirmed,
        savedInvoiceId,
        lowStockWarnings,
        measuredPrompt,
        outOfStockScan,
        barcodeChoices,
        exchangeRate,
        rateUpdatedAt,
        invoiceDiscount,
        blockOversell,
        printEnabled,
      ];
}
