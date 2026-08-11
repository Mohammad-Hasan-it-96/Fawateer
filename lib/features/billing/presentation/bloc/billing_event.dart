part of 'billing_bloc.dart';

abstract class BillingEvent extends Equatable {
  const BillingEvent();
  @override
  List<Object?> get props => [];
}

class ScanBarcodeEvent extends BillingEvent {
  final String barcode;
  const ScanBarcodeEvent(this.barcode);
  @override
  List<Object> get props => [barcode];
}

class AddProductToCartEvent extends BillingEvent {
  final Product product;

  /// When null, a piece add: appends a new line at qty 1 or increments the
  /// existing line by 1. When set (a measured entry — weight in kg), the line is
  /// **set** to this absolute quantity (add-or-replace), never incremented.
  final double? quantity;

  /// The specific physical unit being sold (Plan 012), when the product is
  /// serialized. Each unit becomes its **own** cart line at quantity 1 — lines
  /// are not merged by product — because the serial must stay one-to-one with
  /// the line it is snapshotted onto.
  final ProductUnit? unit;

  const AddProductToCartEvent(this.product, {this.quantity, this.unit});
  @override
  List<Object?> get props => [product, quantity ?? -1, unit];
}

/// Dismisses a pending measured-entry prompt (see [BillingState.measuredPrompt])
/// when the cashier cancels the weight/amount dialog without adding.
class ClearMeasuredPromptEvent extends BillingEvent {
  const ClearMeasuredPromptEvent();
}

/// Dismisses a pending out-of-stock scan notice (see
/// [BillingState.outOfStockScan]) once the POS page has shown it.
class ClearOutOfStockScanEvent extends BillingEvent {
  const ClearOutOfStockScanEvent();
}

/// Dismisses a pending "which one?" chooser (see [BillingState.barcodeChoices])
/// once the POS has asked — whether the cashier picked a product or cancelled.
class ClearBarcodeChoicesEvent extends BillingEvent {
  const ClearBarcodeChoicesEvent();
}

class RemoveProductFromCartEvent extends BillingEvent {
  final String productId;
  const RemoveProductFromCartEvent(this.productId);
  @override
  List<Object> get props => [productId];
}

class UpdateQuantityEvent extends BillingEvent {
  final String productId;
  final double quantity;
  const UpdateQuantityEvent(this.productId, this.quantity);
  @override
  List<Object> get props => [productId, quantity];
}

/// The product behind an open cart line was edited (Plan 013 #4) — re-price the
/// line from the saved product.
///
/// **The open line does pick up the new price.** A cart line is otherwise a
/// snapshot, deliberately: the price at the moment of adding is what the sale
/// records. But this edit was made *from the cart, in order to fix this sale* —
/// the cashier saw a wrong price on the screen and corrected it. Leaving the
/// line at the old number would look exactly like the edit did not save.
///
/// Only affects lines still in the cart; a completed sale is never touched.
class RefreshCartProductEvent extends BillingEvent {
  final Product product;
  const RefreshCartProductEvent(this.product);
  @override
  List<Object> get props => [product];
}

class ClearCartEvent extends BillingEvent {}

/// Set (or clear, with 0) a manual per-line discount in SP on the given product's
/// cart line. The UI resolves a % or fixed entry into this SP amount.
class SetLineDiscountEvent extends BillingEvent {
  final String productId;
  final double discount; // SP; 0 clears
  const SetLineDiscountEvent(this.productId, this.discount);
  @override
  List<Object> get props => [productId, discount];
}

/// Set (or clear, with 0) the whole-cart discount in SP.
class SetCartDiscountEvent extends BillingEvent {
  final double discount; // SP; 0 clears
  const SetCartDiscountEvent(this.discount);
  @override
  List<Object> get props => [discount];
}

/// Load (or reload) the USD→SP exchange rate into the bloc and re-price any
/// foreign lines in the cart. Dispatched at startup and after the rate is
/// edited in Settings → Currency.
class LoadExchangeRateEvent extends BillingEvent {
  const LoadExchangeRateEvent();
}

/// Load (or reload) the strict-inventory flag into the bloc. Dispatched at
/// startup and after the toggle is flipped in Settings → Inventory.
class LoadInventorySettingsEvent extends BillingEvent {
  const LoadInventorySettingsEvent();
}

/// Load (or reload) the show-print-button / auto-print flag into the bloc.
/// Dispatched at startup and after the toggle is flipped in Settings → Hardware.
class LoadPrintSettingsEvent extends BillingEvent {
  const LoadPrintSettingsEvent();
}

class PrintReceiptEvent extends BillingEvent {
  final String shopName;
  final String address1;
  final String address2;
  final String phone;
  final String footer;
  final String currencySymbol;

  const PrintReceiptEvent({
    required this.shopName,
    required this.address1,
    required this.address2,
    required this.phone,
    required this.footer,
    this.currencySymbol = '',
  });

  @override
  List<Object> get props =>
      [shopName, address1, address2, phone, footer, currencySymbol];
}

class ConfirmSaleEvent extends BillingEvent {
  final String shopName;
  final String address1;
  final String address2;
  final String phone;
  final String footer;
  final String currencySymbol;

  /// When set, the sale is booked on credit to this customer (a matching
  /// `charge` ledger entry is written atomically). Null = a cash sale.
  final String? customerId;

  const ConfirmSaleEvent({
    required this.shopName,
    required this.address1,
    required this.address2,
    required this.phone,
    required this.footer,
    this.currencySymbol = '',
    this.customerId,
  });

  @override
  List<Object> get props =>
      [shopName, address1, address2, phone, footer, currencySymbol, customerId ?? ''];
}
