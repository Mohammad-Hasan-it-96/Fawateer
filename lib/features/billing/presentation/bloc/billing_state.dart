part of 'billing_bloc.dart';

/// A localizable billing error. The BLoC sets the case; pages map it to a
/// translated string — no user-facing English lives in the BLoC.
enum BillingError {
  productNotFound,
  saveFailed,
  printerUnavailable,
  printFailed,
}

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
  });

  double get totalAmount => cartItems.fold(0, (sum, item) => sum + item.total);

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
      ];
}
