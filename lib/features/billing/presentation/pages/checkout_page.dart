import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/billing_bloc.dart';
import '../bloc/history_bloc.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE5E5EA);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        context.read<BillingBloc>().add(ClearCartEvent());
        context.go('/pos');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Checkout',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 28, color: Theme.of(context).primaryColor),
            onPressed: () {
              context.read<BillingBloc>().add(ClearCartEvent());
              context.go('/pos');
            },
          ),
        ),
        body: BlocConsumer<BillingBloc, BillingState>(
          listenWhen: (prev, curr) =>
              prev.error != curr.error ||
              prev.printSuccess != curr.printSuccess ||
              (!prev.saleConfirmed && curr.saleConfirmed),
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.error!),
                  backgroundColor: Colors.red));
            }
            if (state.printSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Printed successfully'),
                  backgroundColor: Colors.green));
            }
            if (state.saleConfirmed) {
              // Refresh history so the new sale appears immediately
              try {
                context.read<HistoryBloc>().add(LoadHistoryEvent());
              } catch (_) {}
            }
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
                            // Low stock warning banner
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
                                        'Low stock: ${billingState.lowStockWarnings.join(', ')}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF856404)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Items table
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
                                        _headerCell('Product Name',
                                            TextAlign.left),
                                        _headerCell('Price', TextAlign.right),
                                        _headerCell('Total', TextAlign.right),
                                      ],
                                    ),
                                    ...billingState.cartItems.map((item) {
                                      return TableRow(
                                        children: [
                                          _dataCell(
                                            '${item.quantity} x ${item.product.name}',
                                            TextAlign.left,
                                          ),
                                          _dataCell(
                                            '$currency${item.product.price.toStringAsFixed(2)}',
                                            TextAlign.right,
                                            isSubtitle: true,
                                          ),
                                          _dataCell(
                                            '$currency${item.total.toStringAsFixed(2)}',
                                            TextAlign.right,
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

                    // Bottom bar
                    _buildBottomBar(
                      context: context,
                      billingState: billingState,
                      shop: shop,
                      currency: currency,
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
                  'GRAND TOTAL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '$currency${billingState.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          if (billingState.saleConfirmed) ...[
            // ── Post-confirmation state ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green, size: 22),
                      SizedBox(width: 8),
                      Text('Sale Confirmed!',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green)),
                    ],
                  ),
                  if (billingState.savedInvoiceId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'ID: ...${billingState.savedInvoiceId!.substring(billingState.savedInvoiceId!.length > 8 ? billingState.savedInvoiceId!.length - 8 : 0)}',
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
                                        footer: shop.footerText));
                              }
                            },
                      icon: billingState.isPrinting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.print_outlined),
                      label: const Text('Print'),
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
                        context.go('/pos');
                      },
                      icon: Icons.add_circle_outline,
                      label: 'New Sale',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ] else ...[
            // ── Pre-confirmation state ────────────────────────────────
            PrimaryButton(
              onPressed: billingState.isSaving
                  ? null
                  : () {
                      if (shop != null) {
                        context.read<BillingBloc>().add(ConfirmSaleEvent(
                              shopName: shop.name,
                              address1: shop.addressLine1,
                              address2: shop.addressLine2,
                              phone: shop.phoneNumber,
                              footer: shop.footerText,
                              currencySymbol: shop.currencySymbol,
                            ));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Shop details not loaded'),
                                backgroundColor: Colors.red));
                      }
                    },
              label: 'Confirm Sale',
              icon: Icons.check_circle_outline,
              isLoading: billingState.isSaving,
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
        text.toUpperCase(),
        textAlign: align,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: Colors.grey,
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
