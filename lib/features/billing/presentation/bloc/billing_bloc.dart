import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/repositories/invoice_repository.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/repositories/product_repository.dart';
import 'package:billing_app/features/settings/domain/entities/receipt_line.dart';
import 'package:billing_app/features/settings/domain/repositories/printer_repository.dart';

part 'billing_event.dart';
part 'billing_state.dart';

class BillingBloc extends Bloc<BillingEvent, BillingState> {
  final ProductRepository productRepository;
  final PrinterRepository printerRepository;
  final InvoiceRepository invoiceRepository;

  BillingBloc({
    required this.productRepository,
    required this.printerRepository,
    required this.invoiceRepository,
  }) : super(const BillingState()) {
    on<ScanBarcodeEvent>(_onScanBarcode);
    on<AddProductToCartEvent>(_onAddProductToCart);
    on<RemoveProductFromCartEvent>(_onRemoveProductFromCart);
    on<UpdateQuantityEvent>(_onUpdateQuantity);
    on<ClearCartEvent>(_onClearCart);
    on<PrintReceiptEvent>(_onPrintReceipt);
    on<ConfirmSaleEvent>(_onConfirmSale);
  }

  Future<void> _onScanBarcode(
      ScanBarcodeEvent event, Emitter<BillingState> emit) async {
    final result = await productRepository.getProductByBarcode(event.barcode);
    result.fold(
      (failure) => emit(state.copyWith(
          error: BillingError.productNotFound, errorBarcode: event.barcode)),
      (product) {
        add(AddProductToCartEvent(product));
      },
    );
  }

  void _onAddProductToCart(
      AddProductToCartEvent event, Emitter<BillingState> emit) {
    final cleanState = state.copyWith(error: null, clearError: true);

    final existingIndex = cleanState.cartItems
        .indexWhere((item) => item.product.id == event.product.id);

    List<CartItem> updatedItems;
    if (existingIndex >= 0) {
      final existingItem = cleanState.cartItems[existingIndex];
      updatedItems = List<CartItem>.from(cleanState.cartItems);
      updatedItems[existingIndex] =
          existingItem.copyWith(quantity: existingItem.quantity + 1);
    } else {
      updatedItems = [...cleanState.cartItems, CartItem(product: event.product)];
    }

    final warnings = _computeStockWarnings(updatedItems);
    emit(cleanState.copyWith(
        cartItems: updatedItems, lowStockWarnings: warnings));
  }

  void _onRemoveProductFromCart(
      RemoveProductFromCartEvent event, Emitter<BillingState> emit) {
    final updatedList = state.cartItems
        .where((item) => item.product.id != event.productId)
        .toList();
    emit(state.copyWith(
        cartItems: updatedList, lowStockWarnings: _computeStockWarnings(updatedList)));
  }

  void _onUpdateQuantity(
      UpdateQuantityEvent event, Emitter<BillingState> emit) {
    if (event.quantity <= 0) {
      add(RemoveProductFromCartEvent(event.productId));
      return;
    }

    final index = state.cartItems
        .indexWhere((item) => item.product.id == event.productId);
    if (index >= 0) {
      final items = List<CartItem>.from(state.cartItems);
      items[index] = items[index].copyWith(quantity: event.quantity);
      emit(state.copyWith(
          cartItems: items, lowStockWarnings: _computeStockWarnings(items)));
    }
  }

  void _onClearCart(ClearCartEvent event, Emitter<BillingState> emit) {
    emit(const BillingState());
  }

  Future<void> _onConfirmSale(
      ConfirmSaleEvent event, Emitter<BillingState> emit) async {
    emit(state.copyWith(isSaving: true, clearError: true));

    final invoiceId = const Uuid().v4();
    final invoice = Invoice(
      id: invoiceId,
      createdAt: DateTime.now(),
      totalAmount: state.totalAmount,
    );

    final items = state.cartItems
        .map((cartItem) => InvoiceItem(
              invoiceId: invoiceId,
              productId: cartItem.product.id,
              productName: cartItem.product.name,
              price: cartItem.product.price,
              cost: cartItem.product.cost,
              quantity: cartItem.quantity.toDouble(),
            ))
        .toList();

    // Persist invoice, line items, and stock deduction in one transaction.
    // Stock is decremented relatively inside the DB, so a failed save leaves
    // inventory untouched and a concurrent product edit is never clobbered.
    final saveResult = await invoiceRepository.saveInvoice(invoice, items);
    if (saveResult.isLeft()) {
      emit(state.copyWith(isSaving: false, error: BillingError.saveFailed));
      return;
    }

    emit(state.copyWith(
      isSaving: false,
      saleConfirmed: true,
      savedInvoiceId: invoiceId,
    ));

    // Auto-print the receipt (best-effort — a print failure never blocks a
    // sale that's already committed).
    try {
      final printed = await printerRepository.printReceipt(
        shopName: event.shopName,
        address1: event.address1,
        address2: event.address2,
        phone: event.phone,
        footer: event.footer,
        total: invoice.totalAmount,
        items: _receiptLines(),
      );
      if (printed) emit(state.copyWith(printSuccess: true));
    } catch (_) {
      // Print failure is non-fatal after a confirmed sale.
    }
  }

  Future<void> _onPrintReceipt(
      PrintReceiptEvent event, Emitter<BillingState> emit) async {
    emit(state.copyWith(
        isPrinting: true, printSuccess: false, clearError: true));

    try {
      final printed = await printerRepository.printReceipt(
        shopName: event.shopName,
        address1: event.address1,
        address2: event.address2,
        phone: event.phone,
        footer: event.footer,
        total: state.totalAmount,
        items: _receiptLines(),
      );

      if (printed) {
        emit(state.copyWith(isPrinting: false, printSuccess: true));
      } else {
        emit(state.copyWith(
            isPrinting: false, error: BillingError.printerUnavailable));
        emit(state.copyWith(clearError: true));
      }
    } catch (_) {
      emit(state.copyWith(isPrinting: false, error: BillingError.printFailed));
      emit(state.copyWith(clearError: true));
    }
  }

  /// Map the current cart into printable receipt lines.
  List<ReceiptLine> _receiptLines() => state.cartItems
      .map((i) => ReceiptLine(
            name: i.product.name,
            quantity: i.quantity,
            price: i.product.price,
            total: i.total,
          ))
      .toList();

  List<String> _computeStockWarnings(List<CartItem> items) {
    // i.product.quantity = on-hand inventory; i.quantity = units being sold.
    return items
        .where((i) => i.product.quantity > 0 && i.quantity > i.product.quantity)
        .map((i) => i.product.name)
        .toList();
  }
}
