import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/share/cards/invoice_share_card.dart';
import '../../../../core/share/share_card_action.dart';
import '../../../../core/utils/format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shop/domain/entities/shop.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/entities/invoice_list_item.dart';
import '../bloc/history_bloc.dart';

String _money(String currency, double v) => '$currency${v.toStringAsFixed(2)}';

/// Read-only invoice detail: header (number/date/time/payment/customer), the
/// line items (product / qty / unit price / line total), the total, and a
/// reprint action. Reuses the app-wide [HistoryBloc]: its `itemsCache` (lazy,
/// per-invoice) backs the item list, and [ReprintInvoiceEvent] drives reprint.
class InvoiceDetailPage extends StatefulWidget {
  final InvoiceListItem invoice;
  const InvoiceDetailPage({super.key, required this.invoice});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<HistoryBloc>()
        .add(LoadInvoiceDetailsEvent(widget.invoice.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inv = widget.invoice;
    final currency = (context.watch<ShopBloc>().state is ShopLoaded)
        ? (context.read<ShopBloc>().state as ShopLoaded).shop.currencySymbol
        : '';
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.invoiceDetails,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          BlocBuilder<HistoryBloc, HistoryState>(
            buildWhen: (p, c) => p.itemsCache[inv.id] != c.itemsCache[inv.id],
            builder: (context, state) {
              final items = state.itemsCache[inv.id];
              return IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: l10n.shareAction,
                // Share needs the line items; disabled until they've loaded.
                onPressed: (items == null || items.isEmpty)
                    ? null
                    : () => _shareInvoice(
                        context, l10n, locale, currency, inv, items),
              );
            },
          ),
        ],
      ),
      body: BlocListener<HistoryBloc, HistoryState>(
        listenWhen: (prev, curr) =>
            prev.reprintStatus != curr.reprintStatus &&
            (curr.reprintStatus == ReprintStatus.done ||
                curr.reprintStatus == ReprintStatus.failed),
        listener: (context, state) {
          final ok = state.reprintStatus == ReprintStatus.done;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content:
                  Text(ok ? l10n.printedSuccessfully : l10n.printFailed),
              backgroundColor: ok ? Colors.green : Colors.red,
            ));
        },
        child: BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, state) {
            final items = state.itemsCache[inv.id];
            final failed = state.failedItems.contains(inv.id);
            final reprinting =
                state.reprintStatus == ReprintStatus.printing &&
                    state.reprintingId == inv.id;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      _header(context, l10n, locale, inv),
                      const SizedBox(height: 16),
                      _itemsSection(context, l10n, currency, items, failed),
                    ],
                  ),
                ),
                _footer(context, l10n, currency, inv, reprinting, items),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n, String locale,
      InvoiceListItem inv) {
    final shortId = inv.id.length > 8
        ? '#${inv.id.substring(inv.id.length - 8)}'
        : '#${inv.id}';
    final date = DateFormat.yMMMd(locale).format(inv.createdAt);
    final time = DateFormat.jm(locale).format(inv.createdAt);
    final payment = inv.isCredit ? l10n.paymentCredit : l10n.paymentCash;
    final customer = inv.isCredit
        ? (inv.customerName?.isNotEmpty == true
            ? inv.customerName!
            : l10n.paymentCredit)
        : l10n.walkInCustomer;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _row(l10n.invoiceNumber, shortId, mono: true),
          _row(l10n.dateLabel, date),
          _row(l10n.timeLabel, time),
          _row(l10n.paymentType, payment),
          _row(l10n.customerLabel, customer),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: mono ? 'monospace' : null)),
          ),
        ],
      ),
    );
  }

  Widget _itemsSection(BuildContext context, AppLocalizations l10n,
      String currency, List<InvoiceItem>? items, bool failed) {
    if (items == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: failed
              ? Text(l10n.itemsLoadFailed,
                  style: const TextStyle(color: Colors.red))
              : const CircularProgressIndicator(),
        ),
      );
    }
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
            child: Text(l10n.noItems,
                style: const TextStyle(color: Colors.grey))),
      );
    }

    return Column(
      children: [
        // Column headers.
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(flex: 4, child: _th(l10n.colProduct)),
              Expanded(flex: 2, child: _th(l10n.unitPrice, end: true)),
              Expanded(flex: 2, child: _th(l10n.colTotal, end: true)),
            ],
          ),
        ),
        const Divider(height: 1),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                      Text('× ${formatQty(item.quantity)}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                      if (item.discount > 0)
                        Text('${l10n.discountLabel}: - ${_money(currency, item.discount)}',
                            style:
                                const TextStyle(fontSize: 11, color: Colors.red)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(_money(currency, item.price),
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 14)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(_money(currency, item.total),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _th(String label, {bool end = false}) => Text(
        label,
        textAlign: end ? TextAlign.end : TextAlign.start,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600]),
      );

  Widget _footer(BuildContext context, AppLocalizations l10n, String currency,
      InvoiceListItem inv, bool reprinting, List<InvoiceItem>? items) {
    // Derive the discount breakdown from the snapshotted items + stored total:
    // gross subtotal = Σ price×qty; total discount = subtotal − grand total.
    double? subtotal;
    double totalDiscount = 0;
    if (items != null && items.isNotEmpty) {
      subtotal = items.fold<double>(0, (s, i) => s + i.gross);
      totalDiscount = subtotal - inv.total;
      if (totalDiscount < 0.005) totalDiscount = 0;
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          if (subtotal != null && totalDiscount > 0) ...[
            _sumRow(l10n.subtotalLabel, _money(currency, subtotal)),
            _sumRow(l10n.discountLabel, '- ${_money(currency, totalDiscount)}',
                color: Colors.red),
            const SizedBox(height: 6),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.grandTotal,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              Text(_money(currency, inv.total),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: reprinting ? null : () => _reprint(context, currency),
              icon: reprinting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.print_outlined),
              label: Text(l10n.reprint),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sumRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.grey[800])),
        ],
      ),
    );
  }

  void _reprint(BuildContext context, String currency) {
    final shopState = context.read<ShopBloc>().state;
    final Shop shop = shopState is ShopLoaded ? shopState.shop : const Shop();
    context.read<HistoryBloc>().add(ReprintInvoiceEvent(
          invoiceId: widget.invoice.id,
          total: widget.invoice.total,
          shopName: shop.name,
          address1: shop.addressLine1,
          address2: shop.addressLine2,
          phone: shop.phoneNumber,
          footer: shop.footerText,
          currency: currency,
        ));
  }

  /// Share this stored invoice as a styled PNG receipt (Plan 007). The discount
  /// is derived from the snapshotted items vs. the stored total, exactly like
  /// the footer breakdown.
  Future<void> _shareInvoice(BuildContext context, AppLocalizations l10n,
      String locale, String currency, InvoiceListItem inv,
      List<InvoiceItem> items) async {
    final shopState = context.read<ShopBloc>().state;
    final Shop shop = shopState is ShopLoaded ? shopState.shop : const Shop();
    final subtotal = items.fold<double>(0, (s, i) => s + i.gross);
    var discount = subtotal - inv.total;
    if (discount < 0.005) discount = 0;
    final shortId = inv.id.length > 8
        ? '#${inv.id.substring(inv.id.length - 8)}'
        : '#${inv.id}';
    final card = InvoiceShareCard(
      l10n: l10n,
      currency: currency,
      shopName: shop.name,
      shopAddress1: shop.addressLine1,
      shopAddress2: shop.addressLine2,
      shopPhone: shop.phoneNumber,
      footer: shop.footerText,
      invoiceShortId: shortId,
      dateText: DateFormat.yMMMd(locale).format(inv.createdAt),
      timeText: DateFormat.jm(locale).format(inv.createdAt),
      paymentLabel: inv.isCredit ? l10n.paymentCredit : l10n.paymentCash,
      customerName: inv.isCredit ? inv.customerName : null,
      lines: items
          .map((it) => InvoiceShareLine(
                name: it.productName,
                quantity: it.quantity,
                unitPrice: it.price,
                lineTotal: it.total,
              ))
          .toList(),
      subtotal: subtotal,
      discount: discount,
      total: inv.total,
    );
    await shareCardAsImage(context,
        card: card,
        fileName: 'invoice_${inv.id}.png',
        messageText: shop.name.isNotEmpty ? shop.name : null);
  }
}
