import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

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
    const borderColor = Color(0xFFE5E5EA);
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Table(
                                  border: const TableBorder(
                                    horizontalInside:
                                        BorderSide(color: borderColor),
                                    bottom: BorderSide(color: borderColor),
                                  ),
                                  children: [
                                    TableRow(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF8FAFC),
                                        border: Border(
                                            bottom: BorderSide(
                                                color: borderColor)),
                                      ),
                                      children: [
                                        _headerCell(l10n.colProduct,
                                            TextAlign.start),
                                        _headerCell(
                                            l10n.colPrice, TextAlign.end),
                                        _headerCell(
                                            l10n.colTotal, TextAlign.end),
                                      ],
                                    ),
                                    ...billingState.cartItems.map((item) {
                                      final measured =
                                          item.product.saleType.isMeasured;
                                      return TableRow(
                                        children: [
                                          _dataCell(
                                            measured
                                                ? '${formatQty(item.quantity)} ${l10n.unitKg} × ${item.product.name}'
                                                : '${formatQty(item.quantity)} x ${item.product.name}',
                                            TextAlign.start,
                                          ),
                                          _dataCell(
                                            measured
                                                ? '$currency${item.product.price.toStringAsFixed(2)}/${l10n.unitKg}'
                                                : '$currency${item.product.price.toStringAsFixed(2)}',
                                            TextAlign.end,
                                            isSubtitle: true,
                                          ),
                                          _dataCell(
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
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.grandTotal,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '$currency${billingState.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
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
                            fontSize: 11, color: Colors.grey[400]),
                      ),
                    ),
                ],
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

  Widget _headerCell(String text, TextAlign align) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _dataCell(String text, TextAlign align,
      {bool isBold = false, bool isSubtitle = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: isSubtitle ? 12 : 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: isSubtitle ? Colors.grey[500] : Colors.black87,
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
    final l10n = widget.l10n;
    final customers = context.read<CustomerBloc>().state.customers;
    // Sentinel returned by the "add new customer" tile so we can branch after
    // the sheet closes (vs. a picked CustomerAccount or a plain dismiss).
    const addSentinel = Object();
    final result = await showModalBottomSheet<Object>(
      context: context,
      // The app theme sets bottomSheet background to transparent, so every
      // sheet must supply its own surface — otherwise the list renders over
      // the scrim and looks hidden/see-through.
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(l10n.selectCustomer,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
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
              onTap: () => Navigator.pop(sheetCtx, addSentinel),
            ),
            const Divider(height: 1),
            if (customers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.noCustomers, textAlign: TextAlign.center),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: customers.length,
                  itemBuilder: (_, i) {
                    final acc = customers[i];
                    return ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(acc.customer.name),
                      subtitle: acc.customer.phone.isEmpty
                          ? null
                          : Text(acc.customer.phone),
                      onTap: () => Navigator.pop(sheetCtx, acc),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (identical(result, addSentinel)) {
      await _addCustomerInline();
    } else if (result is CustomerAccount) {
      setState(() {
        _customerId = result.customer.id;
        _customerName = result.customer.name;
      });
    }
  }

  /// Quick-add a customer without leaving checkout. Creates the customer with a
  /// fresh id (so we can select it immediately), dispatches [AddCustomer], and
  /// marks the sale as credit to that customer.
  Future<void> _addCustomerInline() async {
    final l10n = widget.l10n;
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.addNewCustomer),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.customerNameLabel,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.fieldRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.customerPhoneLabel,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogCtx, true);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      final customer = Customer(
        id: const Uuid().v4(),
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        createdAt: DateTime.now(),
      );
      context.read<CustomerBloc>().add(AddCustomer(customer));
      setState(() {
        _customerId = customer.id;
        _customerName = customer.name;
      });
    }
    nameCtrl.dispose();
    phoneCtrl.dispose();
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
    final color = selected ? AppTheme.primaryColor : Colors.grey;
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
                  : Colors.grey.shade300),
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
                    color: selected ? AppTheme.primaryColor : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
