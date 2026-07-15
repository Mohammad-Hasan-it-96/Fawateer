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

  /// Current USD→SP rate (SP per 1 USD), or null if the owner hasn't set one.
  /// Used to price USD products into SP as they enter the cart.
  final double? exchangeRate;

  /// When [exchangeRate] was last set — drives a "your rate is stale" hint.
  final DateTime? rateUpdatedAt;

  /// Manual whole-cart discount in SP, applied on top of any per-line discounts.
  /// Clamped to the subtotal via [effectiveInvoiceDiscount]. 0 = none.
  final double invoiceDiscount;

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
    this.exchangeRate,
    this.rateUpdatedAt,
    this.invoiceDiscount = 0,
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
    Object? exchangeRate = _unset,
    Object? rateUpdatedAt = _unset,
    double? invoiceDiscount,
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
      exchangeRate: identical(exchangeRate, _unset)
          ? this.exchangeRate
          : exchangeRate as double?,
      rateUpdatedAt: identical(rateUpdatedAt, _unset)
          ? this.rateUpdatedAt
          : rateUpdatedAt as DateTime?,
      invoiceDiscount: invoiceDiscount ?? this.invoiceDiscount,
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
        exchangeRate,
        rateUpdatedAt,
        invoiceDiscount,
      ];
}
