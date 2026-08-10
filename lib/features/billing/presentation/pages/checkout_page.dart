import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/share/cards/invoice_share_card.dart';
import '../../../../core/share/share_card_action.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_snack.dart';
import '../../../../core/utils/format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ledger/presentation/widgets/customer_picker.dart';
import '../../../shop/domain/entities/shop.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/billing_bloc.dart';
import '../billing_error_text.dart';
import '../widgets/discount_dialog.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  /// Leave checkout. The cart is preserved if the sale wasn't completed yet, so
  /// the cashier can go back and add a forgotten item without re-scanning. Once
  /// the sale is confirmed there's nothing to keep, so the cart is cleared.
  void _exitToPos(BuildContext context) {
    final billing = context.read<BillingBloc>();
    if (billing.state.saleConfirmed) {
      billing.add(ClearCartEvent());
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/pos');
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).dividerColor;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _exitToPos(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.checkoutTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 28, color: Theme.of(context).primaryColor),
            onPressed: () => _exitToPos(context),
          ),
        ),
        body: BlocConsumer<BillingBloc, BillingState>(
          listenWhen: (prev, curr) =>
              prev.error != curr.error ||
              prev.printSuccess != curr.printSuccess,
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      billingErrorText(state.error!, state.errorBarcode, l10n)),
                  backgroundColor: Colors.red,
                  duration: AppSnackDuration.brief));
            }
            if (state.printSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.printedSuccessfully),
                  backgroundColor: Colors.green,
                  duration: AppSnackDuration.brief));
            }
            // History (incl. today's totals) auto-refreshes via the invoice
            // stream — no manual reload needed here.
          },
          builder: (context, billingState) {
            return BlocBuilder<ShopBloc, ShopState>(
              builder: (context, shopState) {
                final shop = shopState is ShopLoaded ? shopState.shop : null;
                final currency = shop?.currencySymbol ?? '';

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        child: Column(
                          children: [
                            if (billingState.hasUnpricedItems)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDE2E1),
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: const Color(0xFFE57373)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.currency_exchange,
                                        color: Color(0xFFC62828), size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        l10n.exchangeRateMissingError,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFFC62828)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Strict inventory would refuse this cart → a hard
                            // red block (Confirm disabled). Lists the *oversold*
                            // items, which can include sold-out (on-hand 0)
                            // products that the softer amber warning skips.
                            if (billingState.isStockBlocked)
                              _stockNoticeBox(
                                blocking: true,
                                text:
                                    '${l10n.outOfStockPrefix}${billingState.oversoldItems.join(', ')}',
                              )
                            // Otherwise the usual amber low-stock heads-up that
                            // still lets the sale through.
                            else if (billingState.lowStockWarnings.isNotEmpty)
                              _stockNoticeBox(
                                blocking: false,
                                text:
                                    '${l10n.lowStockPrefix}${billingState.lowStockWarnings.join(', ')}',
                              ),

                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Table(
                                  // Serial(م) · Item · Qty · Unit · Unit price ·
                                  // Total — the wholesale-invoice layout the owner
                                  // asked for (Plan 011 #10). Item takes the flex;
                                  // the rest size to content.
                                  columnWidths: const {
                                    0: IntrinsicColumnWidth(),
                                    1: FlexColumnWidth(),
                                    2: IntrinsicColumnWidth(),
                                    3: IntrinsicColumnWidth(),
                                    4: IntrinsicColumnWidth(),
                                    5: IntrinsicColumnWidth(),
                                  },
                                  defaultVerticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  border: TableBorder(
                                    horizontalInside:
                                        BorderSide(color: borderColor),
                                    bottom: BorderSide(color: borderColor),
                                  ),
                                  children: [
                                    TableRow(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        border: Border(
                                            bottom: BorderSide(
                                                color: borderColor)),
                                      ),
                                      children: [
                                        _headerCell(context, l10n.colSerial,
                                            TextAlign.center),
                                        _headerCell(context, l10n.colProduct,
                                            TextAlign.start),
                                        _headerCell(context, l10n.colQty,
                                            TextAlign.center),
                                        _headerCell(context, l10n.colUnit,
                                            TextAlign.center),
                                        _headerCell(context, l10n.colUnitPrice,
                                            TextAlign.end),
                                        _headerCell(context,
                                            l10n.colTotal, TextAlign.end),
                                      ],
                                    ),
                                    ...billingState.cartItems
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final item = entry.value;
                                      final measured =
                                          item.product.saleType.isMeasured;
                                      // Resolved SP unit price; USD lines also
                                      // show their original "$X" sticker.
                                      final spPrice =
                                          '$currency${item.unitPriceSp.toStringAsFixed(2)}';
                                      final priceStr = item.isForeign
                                          ? '$spPrice\n(${item.sellCurrency.label(item.product.price, '')})'
                                          : spPrice;
                                      return TableRow(
                                        children: [
                                          _dataCell(
                                            context,
                                            '${entry.key + 1}',
                                            TextAlign.center,
                                            isSubtitle: true,
                                          ),
                                          _dataCell(context, item.product.name,
                                              TextAlign.start),
                                          _dataCell(
                                            context,
                                            formatQty(item.quantity),
                                            TextAlign.center,
                                          ),
                                          _dataCell(
                                            context,
                                            measured
                                                ? l10n.unitKg
                                                : l10n.unitPiece,
                                            TextAlign.center,
                                            isSubtitle: true,
                                          ),
                                          _dataCell(
                                            context,
                                            priceStr,
                                            TextAlign.end,
                                            isSubtitle: true,
                                          ),
                                          _dataCell(
                                            context,
                                            '$currency${item.total.toStringAsFixed(2)}',
                                            TextAlign.end,
                                            isBold: true,
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),

                    _buildBottomBar(
                      context: context,
                      billingState: billingState,
                      shop: shop,
                      currency: currency,
                      l10n: l10n,
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomBar({
    required BuildContext context,
    required BillingState billingState,
    required shop,
    required String currency,
    required AppLocalizations l10n,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface
            .withValues(alpha: 0.97),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTotals(context, billingState, currency, l10n),
          if (billingState.saleConfirmed) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 22),
                      const SizedBox(width: 8),
                      Text(l10n.saleConfirmed,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green)),
                    ],
                  ),
                  if (billingState.savedInvoiceId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${l10n.invoiceIdPrefix}${billingState.savedInvoiceId!.substring(billingState.savedInvoiceId!.length > 8 ? billingState.savedInvoiceId!.length - 8 : 0)}',
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: OutlinedButton.icon(
                onPressed: () =>
                    _shareReceipt(context, billingState, shop, currency, l10n),
                icon: const Icon(Icons.share_outlined),
                label: Text(l10n.shareAction),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Row(
              children: [
                // Print button hidden when printing is turned off in Settings
                // (Plan 011 #6) — "New Sale" then spans the full width.
                if (billingState.printEnabled)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                      child: OutlinedButton.icon(
                        onPressed: billingState.isPrinting
                            ? null
                            : () {
                                if (shop != null) {
                                  context.read<BillingBloc>().add(
                                      PrintReceiptEvent(
                                          shopName: shop.name,
                                          address1: shop.addressLine1,
                                          address2: shop.addressLine2,
                                          phone: shop.phoneNumber,
                                          footer: shop.footerText,
                                          currencySymbol: currency));
                                }
                              },
                        icon: billingState.isPrinting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.print_outlined),
                        label: Text(l10n.printReceipt),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        billingState.printEnabled ? 8 : 20, 0, 20, 0),
                    child: PrimaryButton(
                      onPressed: () {
                        context.read<BillingBloc>().add(ClearCartEvent());
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/pos');
                        }
                      },
                      icon: Icons.add_circle_outline,
                      label: l10n.newSale,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ] else ...[
            _CreditAwareConfirm(
              billingState: billingState,
              shop: shop,
              currency: currency,
              l10n: l10n,
            ),
          ],
        ],
      ),
    );
  }

  /// Build a styled receipt card from the just-confirmed cart and hand it to the
  /// OS share sheet as a PNG (Plan 007). Payment/customer are omitted — this is
  /// the customer's copy captured straight from the cart state.
  Future<void> _shareReceipt(BuildContext context, BillingState st, dynamic shop,
      String currency, AppLocalizations l10n) async {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final id = st.savedInvoiceId ?? '';
    final shortId =
        id.length > 8 ? '#${id.substring(id.length - 8)}' : '#$id';
    final card = InvoiceShareCard(
      l10n: l10n,
      currency: currency,
      shopName: shop?.name ?? '',
      shopAddress1: shop?.addressLine1 ?? '',
      shopAddress2: shop?.addressLine2 ?? '',
      shopPhone: shop?.phoneNumber ?? '',
      footer: shop?.footerText ?? '',
      invoiceShortId: shortId,
      dateText: DateFormat.yMMMd(locale).format(now),
      timeText: DateFormat.jm(locale).format(now),
      paymentLabel: null,
      customerName: null,
      lines: st.cartItems
          .map((it) => InvoiceShareLine(
                name: it.product.name,
                quantity: it.quantity,
                unitPrice: it.unitPriceSp,
                lineTotal: it.total,
              ))
          .toList(),
      subtotal: st.subtotal,
      discount: st.totalDiscount,
      total: st.totalAmount,
    );
    await shareCardAsImage(context,
        card: card,
        fileName: 'invoice_$id.png',
        messageText: (shop?.name as String?)?.isNotEmpty == true
            ? shop!.name as String
            : null);
  }

  /// Totals block: an editable cart-discount row (before confirm), an optional
  /// subtotal + discount breakdown, then the grand total.
  Widget _buildTotals(BuildContext context, BillingState st, String currency,
      AppLocalizations l10n) {
    final hasDiscount = st.totalDiscount > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          if (!st.saleConfirmed) _cartDiscountRow(context, st, currency, l10n),
          if (hasDiscount) ...[
            _miniRow(context, l10n.subtotalLabel,
                '$currency${st.subtotal.toStringAsFixed(2)}'),
            _miniRow(context, l10n.discountLabel,
                '- $currency${st.totalDiscount.toStringAsFixed(2)}',
                color: Colors.red),
            const SizedBox(height: 4),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.grandTotal,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text('$currency${st.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cartDiscountRow(BuildContext context, BillingState st,
      String currency, AppLocalizations l10n) {
    final has = st.effectiveInvoiceDiscount > 0;
    return InkWell(
      onTap: st.cartItems.isEmpty
          ? null
          : () => _editCartDiscount(context, st, currency),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(has ? Icons.local_offer : Icons.local_offer_outlined,
                    size: 16,
                    color: has
                        ? Colors.red
                        : Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(l10n.cartDiscountLabel,
                    style: TextStyle(
                        fontSize: 13,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
            Text(
              has
                  ? '- $currency${st.effectiveInvoiceDiscount.toStringAsFixed(2)}'
                  : l10n.addDiscountAction,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: has ? Colors.red : AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editCartDiscount(
      BuildContext context, BillingState st, String currency) async {
    final result = await showDiscountDialog(
      context: context,
      base: st.subtotal,
      currency: currency,
      initialDiscount: st.invoiceDiscount,
    );
    if (result != null && context.mounted) {
      context.read<BillingBloc>().add(SetCartDiscountEvent(result));
    }
  }

  Widget _miniRow(BuildContext context, String label, String value,
      {Color? color}) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: muted)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color ?? muted)),
        ],
      ),
    );
  }

  Widget _headerCell(BuildContext context, String text, TextAlign align) {
    return Padding(
      // Tight horizontal padding: the review table now carries 6 columns
      // (Plan 011 #10), so cells must stay compact on a phone width.
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _dataCell(BuildContext context, String text, TextAlign align,
      {bool isBold = false, bool isSubtitle = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: isSubtitle ? 12 : 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: isSubtitle ? scheme.onSurfaceVariant : scheme.onSurface,
        ),
      ),
    );
  }
}

/// A stock notice strip above the cart: red (a strict-inventory *block*) or
/// amber (a soft low-stock heads-up). [text] is the pre-composed prefix + names.
Widget _stockNoticeBox({required bool blocking, required String text}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: blocking ? const Color(0xFFFDE2E1) : const Color(0xFFFFF3CD),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
          color: blocking ? const Color(0xFFE57373) : const Color(0xFFFFD700)),
    ),
    child: Row(
      children: [
        Icon(blocking ? Icons.block : Icons.warning_amber_rounded,
            color: blocking ? const Color(0xFFC62828) : const Color(0xFFB8860B),
            size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 13,
                  color: blocking
                      ? const Color(0xFFC62828)
                      : const Color(0xFF856404))),
        ),
      ],
    ),
  );
}

/// Cash/credit selector + the confirm button. Holds the chosen credit customer
/// locally; on confirm it passes [ConfirmSaleEvent.customerId] (null for cash),
/// which books the debt atomically with the sale.
class _CreditAwareConfirm extends StatefulWidget {
  final BillingState billingState;
  final Shop? shop;
  final String currency;
  final AppLocalizations l10n;

  const _CreditAwareConfirm({
    required this.billingState,
    required this.shop,
    required this.currency,
    required this.l10n,
  });

  @override
  State<_CreditAwareConfirm> createState() => _CreditAwareConfirmState();
}

class _CreditAwareConfirmState extends State<_CreditAwareConfirm> {
  String? _customerId;
  String? _customerName;

  void _confirm() {
    final shop = widget.shop;
    if (shop == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.l10n.shopNotLoaded),
          backgroundColor: Colors.red));
      return;
    }
    context.read<BillingBloc>().add(ConfirmSaleEvent(
          shopName: shop.name,
          address1: shop.addressLine1,
          address2: shop.addressLine2,
          phone: shop.phoneNumber,
          footer: shop.footerText,
          currencySymbol: widget.currency,
          customerId: _customerId,
        ));
  }

  /// Choose the credit customer, including quick-adding one without leaving
  /// checkout. The picker is shared with the invoice detail page's
  /// change-payment action (Plan 016 C-a) — same question, one implementation.
  Future<void> _pickCustomer() async {
    final picked = await pickCustomer(context);
    if (picked == null || !mounted) return;
    setState(() {
      _customerId = picked.id;
      _customerName = picked.name;
    });
  }

  void _selectCash() => setState(() {
        _customerId = null;
        _customerName = null;
      });

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final isCredit = _customerId != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _modeChip(
                  label: l10n.cashSale,
                  icon: Icons.payments_outlined,
                  selected: !isCredit,
                  onTap: _selectCash,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _modeChip(
                  label: isCredit
                      ? l10n.creditToLabel(_customerName ?? '')
                      : l10n.sellOnCredit,
                  icon: Icons.account_balance_wallet_outlined,
                  selected: isCredit,
                  onTap: _pickCustomer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            // Disabled while saving, and hard-disabled when strict inventory
            // would reject the cart (the bloc guards it too, as a backstop).
            onPressed:
                (widget.billingState.isSaving || widget.billingState.isStockBlocked)
                    ? null
                    : _confirm,
            label: l10n.confirmSale,
            icon: Icons.check_circle_outline,
            isLoading: widget.billingState.isSaving,
          ),
        ],
      ),
    );
  }

  Widget _modeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final color = selected ? AppTheme.primaryColor : muted;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected
                  ? AppTheme.primaryColor
                  : Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppTheme.primaryColor : muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

