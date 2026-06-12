part of 'billing_bloc.dart';

class BillingState extends Equatable {
  final List<CartItem> cartItems;
  final String? error;
  final bool isPrinting;
  final bool printSuccess;
  final bool isSaving;
  final bool saleConfirmed;
  final String? savedInvoiceId;
  final List<String> lowStockWarnings;

  const BillingState({
    this.cartItems = const [],
    this.error,
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
    String? error,
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
        isPrinting,
        printSuccess,
        isSaving,
        saleConfirmed,
        savedInvoiceId,
        lowStockWarnings,
      ];
}
