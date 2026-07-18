import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/share/cards/invoice_share_card.dart';
import '../../../../core/share/share_card_action.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ledger/domain/entities/customer.dart';
import '../../../ledger/domain/entities/customer_account.dart';
import '../../../ledger/presentation/bloc/customer_bloc.dart';
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
                  backgroundColor: Colors.red));
            }
            if (state.printSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.printedSuccessfully),
                  backgroundColor: Colors.green));
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
                            if (billingState.lowStockWarnings.isNotEmpty)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3CD),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFFFFD700)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        color: Color(0xFFB8860B), size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${l10n.lowStockPrefix}${billingState.lowStockWarnings.join(', ')}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF856404)),
                                      ),
                                    ),
                                  ],
                                ),
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
                                        _headerCell(context, l10n.colProduct,
                                            TextAlign.start),
                                        _headerCell(context,
                                            l10n.colPrice, TextAlign.end),
                                        _headerCell(context,
                                            l10n.colTotal, TextAlign.end),
                                      ],
                                    ),
                                    ...billingState.cartItems.map((item) {
                                      final measured =
                                          item.product.saleType.isMeasured;
                                      // Resolved SP unit price; USD lines also
                                      // show their original "$X" sticker.
                                      final spPrice =
                                          '$currency${item.unitPriceSp.toStringAsFixed(2)}${measured ? '/${l10n.unitKg}' : ''}';
                                      final priceStr = item.isForeign
                                          ? '$spPrice (${item.sellCurrency.label(item.product.price, '')})'
                                          : spPrice;
                                      return TableRow(
                                        children: [
                                          _dataCell(
                                            context,
                                            measured
                                                ? '${formatQty(item.quantity)} ${l10n.unitKg} × ${item.product.name}'
                                                : '${formatQty(item.quantity)} x ${item.product.name}',
                                            TextAlign.start,
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
                              child: CircularProgressIndicator(strokeWidth: 2))
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
                    padding: const EdgeInsets.fromLTRB(8, 0, 20, 0),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 13,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: isSubtitle ? 12 : 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: isSubtitle ? scheme.onSurfaceVariant : scheme.onSurface,
        ),
      ),
    );
  }
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

  Future<void> _pickCustomer() async {
    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CustomerPickerSheet(),
    );
    if (!mounted) return;
    if (identical(result, _kAddNewCustomer)) {
      await _addCustomerInline();
    } else if (result is CustomerAccount) {
      setState(() {
        _customerId = result.customer.id;
        _customerName = result.customer.name;
      });
    }
  }

  /// Quick-add a customer without leaving checkout. The form lives in a
  /// dedicated stateful sheet ([_AddCustomerSheet]) that owns its controllers,
  /// so they're disposed by the framework only after the route is fully gone —
  /// disposing them here (right after the await) would crash the still-animating
  /// sheet as it rebuilds against disposed controllers.
  Future<void> _addCustomerInline() async {
    final created = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddCustomerSheet(),
    );
    if (created != null && mounted) {
      context.read<CustomerBloc>().add(AddCustomer(created));
      setState(() {
        _customerId = created.id;
        _customerName = created.name;
      });
    }
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
            onPressed: widget.billingState.isSaving ? null : _confirm,
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

/// Sentinel popped by [_CustomerPickerSheet] when the user taps "add new
/// customer" — distinguishes that intent from a picked [CustomerAccount] or a
/// plain dismiss (null) at the call site.
final Object _kAddNewCustomer = Object();

/// Customer picker sheet. Small lists (< 5) show in full; larger lists show a
/// search field plus the first 4, with typing filtering live across everyone.
/// Pops the chosen [CustomerAccount], or [_kAddNewCustomer] for the add tile.
class _CustomerPickerSheet extends StatefulWidget {
  const _CustomerPickerSheet();

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  static const _previewCount = 4;
  static const _searchThreshold = 5;

  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final q = _search.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customers = context.watch<CustomerBloc>().state.customers;
    final showSearch = customers.length >= _searchThreshold;

    // Which rows to display: filtered matches when searching, else the first 4
    // (large list) or everything (small list).
    List<CustomerAccount> visible;
    var hiddenCount = 0;
    if (_query.isNotEmpty) {
      visible = customers
          .where((acc) =>
              acc.customer.name.toLowerCase().contains(_query) ||
              acc.customer.phone.toLowerCase().contains(_query))
          .toList();
    } else if (showSearch) {
      visible = customers.take(_previewCount).toList();
      hiddenCount = customers.length - visible.length;
    } else {
      visible = customers;
    }

    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(l10n.selectCustomer,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Icon(Icons.person_add_alt_1, color: Colors.white),
              ),
              title: Text(l10n.addNewCustomer,
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, _kAddNewCustomer),
            ),
            if (showSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: l10n.searchCustomerHint,
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            const Divider(height: 1),
            if (customers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.noCustomers, textAlign: TextAlign.center),
              )
            else if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.noMatchingCustomers,
                    textAlign: TextAlign.center),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: visible.length,
                  itemBuilder: (_, i) {
                    final acc = visible[i];
                    return ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(acc.customer.name),
                      subtitle: acc.customer.phone.isEmpty
                          ? null
                          : Text(acc.customer.phone),
                      onTap: () => Navigator.pop(context, acc),
                    );
                  },
                ),
              ),
            if (hiddenCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(l10n.andMoreTypeToSearch(hiddenCount),
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Keyboard-aware quick-add customer form. Owns its controllers (disposed in
/// [dispose], i.e. after the sheet's exit animation completes) and pops the
/// created [Customer] on save so the caller can select it immediately.
class _AddCustomerSheet extends StatefulWidget {
  const _AddCustomerSheet();

  @override
  State<_AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends State<_AddCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// True if a customer already has this name (case-insensitive, trimmed),
  /// checked against the live [CustomerBloc] list.
  bool _isDuplicateName(String value) {
    final needle = value.trim().toLowerCase();
    return context.read<CustomerBloc>().state.customers.any(
        (acc) => acc.customer.name.trim().toLowerCase() == needle);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Customer(
        id: const Uuid().v4(),
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Text(l10n.addNewCustomer,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.customerNameLabel,
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.fieldRequired;
                if (_isDuplicateName(v)) return l10n.duplicateCustomerName;
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: l10n.customerPhoneLabel,
                prefixIcon: const Icon(Icons.phone_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
