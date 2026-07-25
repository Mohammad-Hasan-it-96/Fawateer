import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:billing_app/features/attributes/domain/entities/attribute_definition.dart';
import 'package:billing_app/features/attributes/domain/repositories/attribute_definition_repository.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/repositories/invoice_repository.dart';
import 'package:billing_app/core/currency/exchange_rate_service.dart';
import 'package:billing_app/core/settings/inventory_settings_service.dart';
import 'package:billing_app/features/product/domain/entities/price_currency.dart';
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
  final ExchangeRateService exchangeRateService;
  final InventorySettingsService inventorySettingsService;
  final AttributeDefinitionRepository attributeRepository;

  /// Active custom fields flagged *show on receipt* (Plan 010), kept fresh via a
  /// subscription so a field the owner adds/edits mid-session prints without a
  /// restart. Read synchronously when building receipt lines and the sale-time
  /// snapshot, so it's cached rather than fetched per sale.
  List<AttributeDefinition> _receiptDefs = const [];
  StreamSubscription<List<AttributeDefinition>>? _receiptDefsSub;

  BillingBloc({
    required this.productRepository,
    required this.printerRepository,
    required this.invoiceRepository,
    required this.exchangeRateService,
    required this.inventorySettingsService,
    required this.attributeRepository,
  }) : super(const BillingState()) {
    _receiptDefsSub = attributeRepository.watchDefinitions().listen((defs) {
      _receiptDefs = defs
          .where((d) => !d.isArchived && d.showOnReceipt)
          .toList();
    });
    on<ScanBarcodeEvent>(_onScanBarcode);
    on<AddProductToCartEvent>(_onAddProductToCart);
    on<RemoveProductFromCartEvent>(_onRemoveProductFromCart);
    on<UpdateQuantityEvent>(_onUpdateQuantity);
    on<ClearMeasuredPromptEvent>((event, emit) =>
        emit(state.copyWith(clearMeasuredPrompt: true)));
    on<ClearOutOfStockScanEvent>((event, emit) =>
        emit(state.copyWith(clearOutOfStockScan: true)));
    on<ClearCartEvent>(_onClearCart);
    on<PrintReceiptEvent>(_onPrintReceipt);
    on<ConfirmSaleEvent>(_onConfirmSale);
    on<LoadExchangeRateEvent>(_onLoadExchangeRate);
    on<LoadInventorySettingsEvent>(_onLoadInventorySettings);
    on<SetLineDiscountEvent>(_onSetLineDiscount);
    on<SetCartDiscountEvent>(_onSetCartDiscount);
  }

  /// Load the strict-inventory flag into state. Dispatched at startup and again
  /// whenever the owner flips the toggle in Settings, so the checkout gate and
  /// the on-screen block reflect the current setting without a restart.
  Future<void> _onLoadInventorySettings(
      LoadInventorySettingsEvent event, Emitter<BillingState> emit) async {
    final block = await inventorySettingsService.isBlockOversellEnabled();
    emit(state.copyWith(blockOversell: block));
  }

  void _onSetLineDiscount(
      SetLineDiscountEvent event, Emitter<BillingState> emit) {
    final index =
        state.cartItems.indexWhere((i) => i.product.id == event.productId);
    if (index < 0) return;
    final items = List<CartItem>.from(state.cartItems);
    final d = event.discount < 0 ? 0.0 : event.discount;
    items[index] = items[index].copyWith(discount: d);
    emit(state.copyWith(cartItems: items));
  }

  void _onSetCartDiscount(
      SetCartDiscountEvent event, Emitter<BillingState> emit) {
    emit(state.copyWith(
        invoiceDiscount: event.discount < 0 ? 0.0 : event.discount));
  }

  /// Build a cart line, resolving a USD-priced product to whole SP at the
  /// current rate. SP products pass through unchanged. A USD product with no
  /// valid rate is left *unpriced* (fxRate 0) so the checkout guard blocks it.
  CartItem _priceLine(Product p, double qty) {
    if (p.priceCurrency == PriceCurrency.usd) {
      final rate = state.exchangeRate;
      final sp = usdToSp(p.price, rate);
      if (sp != null) {
        return CartItem(
          product: p,
          quantity: qty,
          unitPriceSp: sp,
          unitCostSp: usdToSp(p.cost, rate) ?? 0,
          fxRate: rate!,
        );
      }
      return CartItem(
          product: p, quantity: qty, unitPriceSp: 0, unitCostSp: 0, fxRate: 0);
    }
    return CartItem(
        product: p, quantity: qty, unitPriceSp: p.price, unitCostSp: p.cost);
  }

  /// Load the current exchange rate and re-price any foreign lines already in
  /// the cart, so setting/changing the rate keeps the displayed SP consistent.
  Future<void> _onLoadExchangeRate(
      LoadExchangeRateEvent event, Emitter<BillingState> emit) async {
    final rate = await exchangeRateService.getRate();
    final updatedAt = await exchangeRateService.getUpdatedAt();
    final rebuilt = state.cartItems.map((i) {
      if (!i.isForeign) return i;
      final sp = usdToSp(i.product.price, rate);
      if (sp == null) {
        return i.copyWith(unitPriceSp: 0, unitCostSp: 0, fxRate: 0);
      }
      return i.copyWith(
          unitPriceSp: sp,
          unitCostSp: usdToSp(i.product.cost, rate) ?? 0,
          fxRate: rate!);
    }).toList();
    emit(state.copyWith(
        cartItems: rebuilt, exchangeRate: rate, rateUpdatedAt: updatedAt));
  }

  Future<void> _onScanBarcode(
      ScanBarcodeEvent event, Emitter<BillingState> emit) async {
    final result = await productRepository.getProductByBarcode(event.barcode);
    result.fold(
      (failure) {
        // Bloc drops an emit equal to the current state, so scanning the same
        // unknown barcode twice in a row used to produce *nothing* the second
        // time — no dialog, no message, the scan simply vanished. Clearing
        // first makes every scan a real transition the UI can react to.
        if (state.error == BillingError.productNotFound &&
            state.errorBarcode == event.barcode) {
          emit(state.copyWith(clearError: true));
        }
        emit(state.copyWith(
            error: BillingError.productNotFound, errorBarcode: event.barcode));
      },
      (product) {
        // A measured product (e.g. sold by weight) needs a weight/amount entry
        // first — surface it to the UI instead of auto-adding one unit.
        if (product.saleType.isMeasured) {
          emit(state.copyWith(measuredPrompt: product, clearError: true));
        } else {
          // A stock-tracked product that has run out is still added (overselling
          // is allowed by default), but we flag it so the POS shows a red
          // "out of stock" notice — the shopkeeper needs to know the item is
          // finished instead of hunting the shelf (Plan 011 #8). The flag rides
          // through the AddProductToCartEvent below (which preserves it).
          if (product.isOutOfStock) {
            emit(state.copyWith(outOfStockScan: product, clearError: true));
          }
          add(AddProductToCartEvent(product));
        }
      },
    );
  }

  void _onAddProductToCart(
      AddProductToCartEvent event, Emitter<BillingState> emit) {
    // Adding an item starts a fresh sale: clear any error, the sticky "sale
    // confirmed" flags from a previous sale, and any pending measured prompt.
    final cleanState = state.copyWith(
        error: null,
        clearError: true,
        clearSale: true,
        clearMeasuredPrompt: true);

    final existingIndex = cleanState.cartItems
        .indexWhere((item) => item.product.id == event.product.id);

    // The just-touched line goes to the TOP of the cart (Plan 011 #4) so it
    // stays visible for price confirmation on a long cart, instead of scrolling
    // off the bottom. New scans prepend; a re-scan of an existing line updates
    // its quantity and moves it up too.
    List<CartItem> updatedItems;
    if (existingIndex >= 0) {
      final existingItem = cleanState.cartItems[existingIndex];
      // A measured entry (event.quantity set) sets the line absolutely; a piece
      // add increments by 1.
      final newQuantity = event.quantity ?? existingItem.quantity + 1;
      updatedItems = [
        existingItem.copyWith(quantity: newQuantity),
        for (var i = 0; i < cleanState.cartItems.length; i++)
          if (i != existingIndex) cleanState.cartItems[i],
      ];
    } else {
      updatedItems = [
        _priceLine(event.product, event.quantity ?? 1),
        ...cleanState.cartItems,
      ];
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
    // Reset the cart and every per-sale flag, but carry the session-loaded
    // settings across: the exchange rate and the strict-inventory flag are
    // dispatched once at startup, never after a sale, so emitting a bare
    // `const BillingState()` here would silently drop them — the next sale
    // would then treat USD lines as unpriced and forget strict inventory until
    // the app restarts.
    emit(BillingState(
      exchangeRate: state.exchangeRate,
      rateUpdatedAt: state.rateUpdatedAt,
      blockOversell: state.blockOversell,
    ));
  }

  Future<void> _onConfirmSale(
      ConfirmSaleEvent event, Emitter<BillingState> emit) async {
    // Re-entrancy guard: a double-tap enqueues two events. The first flips
    // isSaving synchronously (before the first await below), so the second is
    // dropped here — preventing duplicate invoices and double stock deduction.
    // `saleConfirmed` also blocks a re-confirm of an already-saved sale.
    if (state.isSaving || state.saleConfirmed) return;

    // Never persist an empty/zero-total sale.
    if (state.cartItems.isEmpty) {
      emit(state.copyWith(error: BillingError.emptyCart));
      return;
    }

    // A USD-priced line with no exchange rate can't be converted to SP — block
    // the sale rather than book a wrong (or zero) total. The owner sets the
    // rate in Settings → Currency.
    if (state.cartItems.any((i) => i.isUnpriced)) {
      emit(state.copyWith(error: BillingError.exchangeRateMissing));
      return;
    }

    // Strict inventory (opt-in): refuse to sell any line past its on-hand count,
    // sold-out items included (see [BillingState.oversoldItems] — this is NOT
    // the softer `lowStockWarnings` predicate, which skips untracked items). Off
    // by default; overselling stays allowed.
    if (state.isStockBlocked) {
      emit(state.copyWith(error: BillingError.insufficientStock));
      return;
    }

    emit(state.copyWith(isSaving: true, clearError: true));

    final invoiceId = const Uuid().v4();
    final invoice = Invoice(
      id: invoiceId,
      createdAt: DateTime.now(),
      totalAmount: state.totalAmount,
      invoiceDiscount: state.effectiveInvoiceDiscount,
    );

    final items = state.cartItems
        .map((cartItem) => InvoiceItem(
              invoiceId: invoiceId,
              productId: cartItem.product.id,
              // Resolved SP values — the books settle in SP regardless of how
              // the product was priced. The original currency/rate/price are
              // snapshotted for display & audit only.
              productName: cartItem.product.name,
              price: cartItem.unitPriceSp,
              cost: cartItem.unitCostSp,
              quantity: cartItem.quantity,
              priceCurrency: cartItem.sellCurrency.name,
              fxRate: cartItem.fxRate,
              priceOriginal: cartItem.product.price,
              discount: cartItem.effectiveDiscount,
              // Freeze the show-on-receipt custom fields (Plan 010) so a reprint
              // is immune to later product/definition edits.
              attributesSnapshot: _printableAttrsJson(cartItem.product),
            ))
        .toList();

    // Persist invoice, line items, and stock deduction in one transaction.
    // Stock is decremented relatively inside the DB, so a failed save leaves
    // inventory untouched and a concurrent product edit is never clobbered.
    final saveResult = await invoiceRepository.saveInvoice(invoice, items,
        customerId: event.customerId);
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
        currency: event.currencySymbol,
        total: invoice.totalAmount,
        items: _receiptLines(),
      );
      if (printed) {
        emit(state.copyWith(printSuccess: true));
      } else {
        // Say so. Silence here read as "printed fine" while no receipt came
        // out — the cashier has no way to tell a dead Bluetooth link from a
        // slow printer, and would hand the customer nothing. Matches what the
        // manual print button already reports.
        emit(state.copyWith(error: BillingError.printerUnavailable));
        emit(state.copyWith(clearError: true));
      }
    } catch (_) {
      // Non-fatal — the sale is already committed — but still reported.
      emit(state.copyWith(error: BillingError.printFailed));
      emit(state.copyWith(clearError: true));
    }
  }

  Future<void> _onPrintReceipt(
      PrintReceiptEvent event, Emitter<BillingState> emit) async {
    // Drop a second tap while a print is already in flight.
    if (state.isPrinting) return;
    emit(state.copyWith(
        isPrinting: true, printSuccess: false, clearError: true));

    try {
      final printed = await printerRepository.printReceipt(
        shopName: event.shopName,
        address1: event.address1,
        address2: event.address2,
        phone: event.phone,
        footer: event.footer,
        currency: event.currencySymbol,
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
            // Print the resolved SP unit price so the receipt reconciles with
            // the SP grand total (a USD sticker is converted before printing).
            price: i.unitPriceSp,
            total: i.total,
            // Receipts render as an Arabic bitmap; tag weighed lines with the
            // kg unit so "0.333 كغ × رز" reads clearly.
            unit: i.product.saleType.isMeasured ? 'كغ' : '',
            attributes: _printableAttrStrings(i.product),
          ))
      .toList();

  /// Printable custom fields for a product (Plan 010) as `{label: value}` — the
  /// *show-on-receipt* definitions that have a value on this product, with the
  /// unit appended so the stored snapshot is self-contained (needs no later
  /// definition lookup to reprint).
  Map<String, String> _printableAttrs(Product p) {
    final out = <String, String>{};
    for (final d in _receiptDefs) {
      final v = p.attributes[d.id];
      if (v == null || v.isEmpty) continue;
      out[d.label] = d.unit.isEmpty ? v : '$v ${d.unit}';
    }
    return out;
  }

  /// The printable pairs as "label: value" display lines for a live receipt.
  List<String> _printableAttrStrings(Product p) =>
      _printableAttrs(p).entries.map((e) => '${e.key}: ${e.value}').toList();

  /// JSON snapshot of the printable pairs, frozen onto the sale line ('' none).
  String _printableAttrsJson(Product p) {
    final m = _printableAttrs(p);
    return m.isEmpty ? '' : jsonEncode(m);
  }

  @override
  Future<void> close() {
    _receiptDefsSub?.cancel();
    return super.close();
  }

  List<String> _computeStockWarnings(List<CartItem> items) {
    // i.product.quantity = on-hand inventory; i.quantity = units being sold.
    // Warn when selling more than on-hand for a *tracked* product — one the shop
    // cares about, i.e. it has a positive on-hand count OR a low-stock alert set.
    // This surfaces the out-of-stock case (on-hand 0 on a tracked item) that a
    // bare `quantity > 0` check missed, while staying silent for untracked items
    // (on-hand 0, no alert) so loose/produce items don't warn on every sale.
    return items
        .where((i) =>
            (i.product.quantity > 0 || i.product.minStockAlert > 0) &&
            i.quantity > i.product.quantity)
        .map((i) => i.product.name)
        .toList();
  }
}
