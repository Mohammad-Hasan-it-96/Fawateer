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
import 'package:billing_app/core/settings/print_settings_service.dart';
import 'package:billing_app/features/product/domain/entities/price_currency.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/entities/product_unit.dart';
import 'package:billing_app/features/product/domain/repositories/product_repository.dart';
import 'package:billing_app/features/product/domain/repositories/product_unit_repository.dart';
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
  final PrintSettingsService printSettingsService;
  final AttributeDefinitionRepository attributeRepository;

  /// Serialized inventory (Plan 012). Used only for the second scan path — a
  /// barcode miss falls through to a serial lookup — so a POS with no
  /// serialized products never touches it.
  final ProductUnitRepository productUnitRepository;

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
    required this.printSettingsService,
    required this.attributeRepository,
    required this.productUnitRepository,
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
    on<LoadPrintSettingsEvent>(_onLoadPrintSettings);
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

  /// Load the show-print-button / auto-print flag into state (Plan 011 #6).
  /// Dispatched at startup and whenever the owner flips the toggle in Settings,
  /// so the checkout hides its print button and skips auto-print without a
  /// restart.
  Future<void> _onLoadPrintSettings(
      LoadPrintSettingsEvent event, Emitter<BillingState> emit) async {
    final enabled = await printSettingsService.isPrintButtonEnabled();
    emit(state.copyWith(printEnabled: enabled));
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
  CartItem _priceLine(Product p, double qty, {ProductUnit? unit}) {
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
          unit: unit,
        );
      }
      return CartItem(
          product: p,
          quantity: qty,
          unitPriceSp: 0,
          unitCostSp: 0,
          fxRate: 0,
          unit: unit);
    }
    return CartItem(
        product: p,
        quantity: qty,
        unitPriceSp: p.price,
        unitCostSp: p.cost,
        unit: unit);
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
    if (result.isLeft()) {
      // Second scan path (Plan 012 D6): barcode first — overwhelmingly the
      // common case and already indexed — then fall through to a serial lookup,
      // so scanning the IMEI on a handset's label picks that exact unit.
      final handled = await _tryScanAsSerial(event.barcode, emit);
      if (handled) return;
    }
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

  /// Try [code] as an IMEI/serial (Plan 012). Returns true when it matched a
  /// unit and the scan was fully handled — including the "known but not
  /// sellable" case, which is deliberately *not* reported as `productNotFound`:
  /// the serial IS on file, so sending the cashier to hunt the shelf for a
  /// handset that sold last week would be actively misleading.
  Future<bool> _tryScanAsSerial(String code, Emitter<BillingState> emit) async {
    final found = await productUnitRepository.findBySerial(code);
    final unit = found.fold<ProductUnit?>((_) => null, (u) => u);
    if (unit == null) return false;

    if (!unit.isAvailable) {
      // Re-emit cleanly so a repeated scan of the same sold handset still
      // registers as a transition (same reasoning as the not-found path).
      if (state.error == BillingError.unitNotAvailable &&
          state.errorBarcode == code) {
        emit(state.copyWith(clearError: true));
      }
      emit(state.copyWith(
          error: BillingError.unitNotAvailable, errorBarcode: code));
      return true;
    }

    final productResult = await productRepository.getProductById(unit.productId);
    return productResult.match(
      // The unit points at a SKU that no longer exists. Fall through to the
      // normal not-found path rather than inventing a line with no product.
      (_) => false,
      (product) {
        add(AddProductToCartEvent(product, unit: unit));
        return true;
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

    // Serialized lines are matched by **unit**, not by product (Plan 012 D5):
    // two identical handsets are two lines carrying two IMEIs, never one line
    // at quantity 2, because the serial is snapshotted per line. Re-scanning the
    // same handset therefore finds its own line and leaves the quantity at 1
    // rather than inventing a second phone.
    final unit = event.unit;
    final existingIndex = unit != null
        ? cleanState.cartItems.indexWhere((item) => item.unit?.id == unit.id)
        : cleanState.cartItems
            .indexWhere((item) => item.unit == null && item.product.id == event.product.id);

    // The just-touched line goes to the TOP of the cart (Plan 011 #4) so it
    // stays visible for price confirmation on a long cart, instead of scrolling
    // off the bottom. New scans prepend; a re-scan of an existing line updates
    // its quantity and moves it up too.
    List<CartItem> updatedItems;
    if (existingIndex >= 0) {
      final existingItem = cleanState.cartItems[existingIndex];
      // A measured entry (event.quantity set) sets the line absolutely; a piece
      // add increments by 1. A serialized line stays at 1 — there is exactly one
      // of that handset, so re-scanning it must not claim we're selling two.
      final newQuantity =
          unit != null ? 1.0 : (event.quantity ?? existingItem.quantity + 1);
      updatedItems = [
        existingItem.copyWith(quantity: newQuantity),
        for (var i = 0; i < cleanState.cartItems.length; i++)
          if (i != existingIndex) cleanState.cartItems[i],
      ];
    } else {
      updatedItems = [
        // A serialized line is always one handset, whatever quantity was passed.
        _priceLine(event.product, unit != null ? 1 : (event.quantity ?? 1),
            unit: unit),
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
      printEnabled: state.printEnabled,
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
              // Freeze how it was sold (Plan 011 #10) so the unit survives on
              // reprints and the invoice table never has to guess kg-vs-piece.
              saleType: cartItem.product.saleType.name,
              // Freeze the IMEI/serial (Plan 012) so the line still names the
              // exact handset it sold even if the unit row is later deleted.
              serialSnapshot: cartItem.unit?.serial ?? '',
            ))
        .toList();

    // The physical units this cart consumed. Marked sold inside the sale's own
    // transaction, so a unit is never burned by an invoice that failed to save.
    final soldUnitIds = state.cartItems
        .map((c) => c.unit?.id)
        .whereType<String>()
        .toList();

    // Persist invoice, line items, and stock deduction in one transaction.
    // Stock is decremented relatively inside the DB, so a failed save leaves
    // inventory untouched and a concurrent product edit is never clobbered.
    final saveResult = await invoiceRepository.saveInvoice(invoice, items,
        customerId: event.customerId, soldUnitIds: soldUnitIds);
    if (saveResult.isLeft()) {
      emit(state.copyWith(isSaving: false, error: BillingError.saveFailed));
      return;
    }

    emit(state.copyWith(
      isSaving: false,
      saleConfirmed: true,
      savedInvoiceId: invoiceId,
    ));

    // Printing turned off in Settings (Plan 011 #6): the shop has no printer, so
    // don't auto-print and don't nag with a "printer not connected" notice.
    if (!state.printEnabled) return;

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
            attributes: [
              // Same sub-line treatment as the reprint path, so the original
              // receipt and its reprint are identical (Plan 012).
              if (i.unit != null && i.unit!.serial.isNotEmpty)
                '$kSerialReceiptLabel: ${i.unit!.serial}',
              ..._printableAttrStrings(i.product),
            ],
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
