part of 'billing_bloc.dart';

abstract class BillingEvent extends Equatable {
  const BillingEvent();
  @override
  List<Object> get props => [];
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

  const AddProductToCartEvent(this.product, {this.quantity});
  @override
  List<Object> get props => [product, quantity ?? -1];
}

/// Dismisses a pending measured-entry prompt (see [BillingState.measuredPrompt])
/// when the cashier cancels the weight/amount dialog without adding.
class ClearMeasuredPromptEvent extends BillingEvent {
  const ClearMeasuredPromptEvent();
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

class ClearCartEvent extends BillingEvent {}

/// Load (or reload) the USD→SP exchange rate into the bloc and re-price any
/// foreign lines in the cart. Dispatched at startup and after the rate is
/// edited in Settings → Currency.
class LoadExchangeRateEvent extends BillingEvent {
  const LoadExchangeRateEvent();
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
