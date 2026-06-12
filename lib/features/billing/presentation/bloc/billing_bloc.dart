import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/repositories/invoice_repository.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/usecases/product_usecases.dart';
import '../../../../core/utils/printer_helper.dart';
import 'package:billing_app/features/settings/domain/repositories/printer_repository.dart';

part 'billing_event.dart';
part 'billing_state.dart';

class BillingBloc extends Bloc<BillingEvent, BillingState> {
  final GetProductByBarcodeUseCase getProductByBarcodeUseCase;
  final PrinterRepository printerRepository;
  final InvoiceRepository invoiceRepository;
  final UpdateProductUseCase updateProductUseCase;

  BillingBloc({
    required this.getProductByBarcodeUseCase,
    required this.printerRepository,
    required this.invoiceRepository,
    required this.updateProductUseCase,
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
    final result = await getProductByBarcodeUseCase(event.barcode);
    result.fold(
      (failure) =>
          emit(state.copyWith(error: 'Product not found: ${event.barcode}')),
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
              quantity: cartItem.quantity,
            ))
        .toList();

    // Save invoice to DB
    final saveResult = await invoiceRepository.saveInvoice(invoice, items);
    if (saveResult.isLeft()) {
      final failure = saveResult.fold((l) => l, (r) => null)!;
      emit(state.copyWith(isSaving: false, error: failure.message));
      return;
    }

    // Deduct stock (best-effort — never block a confirmed sale)
    for (final cartItem in state.cartItems) {
      final newStock = cartItem.product.stock - cartItem.quantity;
      await updateProductUseCase(
          cartItem.product.copyWith(stock: newStock));
    }

    emit(state.copyWith(
      isSaving: false,
      saleConfirmed: true,
      savedInvoiceId: invoiceId,
    ));

    // Auto-print if printer is connected
    final printerHelper = PrinterHelper();
    if (!printerHelper.isConnected) {
      final savedMac = await printerRepository.getSavedPrinterMac();
      if (savedMac != null) {
        await printerHelper.connect(savedMac);
      }
    }
    if (printerHelper.isConnected) {
      try {
        final receiptItems = state.cartItems
            .map((item) => {
                  'name': item.product.name,
                  'qty': item.quantity,
                  'price': item.product.price,
                  'total': item.total,
                })
            .toList();
        await printerHelper.printReceipt(
          shopName: event.shopName,
          address1: event.address1,
          address2: event.address2,
          phone: event.phone,
          items: receiptItems,
          total: invoice.totalAmount,
          footer: event.footer,
        );
        emit(state.copyWith(printSuccess: true));
      } catch (_) {
        // Print failure is non-fatal after a confirmed sale
      }
    }
  }

  Future<void> _onPrintReceipt(
      PrintReceiptEvent event, Emitter<BillingState> emit) async {
    final printerHelper = PrinterHelper();

    if (!printerHelper.isConnected) {
      final savedMac = await printerRepository.getSavedPrinterMac();
      if (savedMac != null) {
        final connected = await printerHelper.connect(savedMac);
        if (!connected) {
          emit(state.copyWith(
              error: 'Failed to auto-connect to printer!', clearError: false));
          emit(state.copyWith(clearError: true));
          return;
        }
      } else {
        emit(state.copyWith(
            error: 'Printer not connected & no saved printer found!',
            clearError: false));
        emit(state.copyWith(clearError: true));
        return;
      }
    }

    emit(state.copyWith(
        isPrinting: true, printSuccess: false, clearError: true));

    try {
      final items = state.cartItems
          .map((item) => {
                'name': item.product.name,
                'qty': item.quantity,
                'price': item.product.price,
                'total': item.total,
              })
          .toList();

      await printerHelper.printReceipt(
          shopName: event.shopName,
          address1: event.address1,
          address2: event.address2,
          phone: event.phone,
          items: items,
          total: state.totalAmount,
          footer: event.footer);

      emit(state.copyWith(isPrinting: false, printSuccess: true));
    } catch (e) {
      emit(state.copyWith(
          isPrinting: false, error: 'Print failed: $e', clearError: false));
      emit(state.copyWith(clearError: true));
    }
  }

  List<String> _computeStockWarnings(List<CartItem> items) {
    return items
        .where((i) => i.product.stock > 0 && i.quantity > i.product.stock)
        .map((i) => i.product.name)
        .toList();
  }
}
