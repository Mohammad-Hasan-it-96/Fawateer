import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/security/manager_guard.dart';
import '../../../../core/share/cards/invoice_share_card.dart';
import '../../../../core/share/share_card_action.dart';
import '../../../../core/utils/format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ledger/presentation/widgets/customer_picker.dart';
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
  /// The invoice as this page currently understands it.
  ///
  /// Held in state rather than read from `widget` because a payment correction
  /// (Plan 016 C-a) changes the derived payment fields while the page is open.
  /// It is not re-read from the list either: the list window is *filtered*, so
  /// switching a sale from cash to credit under a "cash only" filter drops the
  /// row out of the window entirely — and the page would fall back to the stale
  /// value it was pushed with.
  late InvoiceListItem _invoice;

  /// The payment correction awaiting its write, applied to [_invoice] only once
  /// the BLoC reports success.
  _PaymentChoice? _pendingChoice;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
    context.read<HistoryBloc>().add(LoadInvoiceDetailsEvent(_invoice.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inv = _invoice;
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
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: l10n.deleteInvoiceAction,
            onPressed: () => _confirmDelete(context, l10n, inv, currency),
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<HistoryBloc, HistoryState>(
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
          ),
          BlocListener<HistoryBloc, HistoryState>(
            listenWhen: (prev, curr) =>
                prev.deleteStatus != curr.deleteStatus &&
                (curr.deleteStatus == DeleteStatus.done ||
                    curr.deleteStatus == DeleteStatus.failed),
            listener: (context, state) {
              final ok = state.deleteStatus == DeleteStatus.done;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(
                      ok ? l10n.invoiceDeleted : l10n.invoiceDeleteFailed),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ));
              // The invoice this page is showing no longer exists — staying
              // here would leave the shop reading a sale that has been undone.
              if (ok && context.canPop()) context.pop();
            },
          ),
          BlocListener<HistoryBloc, HistoryState>(
            listenWhen: (prev, curr) =>
                prev.paymentChangeStatus != curr.paymentChangeStatus &&
                (curr.paymentChangeStatus == PaymentChangeStatus.done ||
                    curr.paymentChangeStatus == PaymentChangeStatus.failed),
            listener: (context, state) {
              final ok = state.paymentChangeStatus == PaymentChangeStatus.done;
              final choice = _pendingChoice;
              _pendingChoice = null;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(
                      ok ? l10n.paymentChanged : l10n.paymentChangeFailed),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ));
              if (ok && choice != null) {
                setState(() {
                  _invoice = _invoice.withPayment(
                    isCredit: choice.customerId != null,
                    customerName: choice.customerName,
                    customerId: choice.customerId,
                  );
                });
              }
            },
          ),
        ],
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _row(l10n.invoiceNumber, shortId, mono: true),
          _row(l10n.dateLabel, date),
          _row(l10n.timeLabel, time),
          _row(l10n.paymentType, payment),
          _row(l10n.customerLabel, customer),
          const SizedBox(height: 4),
          // Sits with the payment/customer rows it edits, not among the app-bar
          // actions: those act on the whole sale (share it, delete it), while
          // this one only corrects the two lines directly above it.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => _openChangePayment(context, l10n),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(l10n.changePaymentAction),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Correct how this sale was paid (Plan 016 C-a).
  ///
  /// The choice is held until the write reports back, and the header is
  /// rewritten only on success. Painting it optimistically would be worse than
  /// a moment's delay: a failed save that still showed the new customer would
  /// tell the shop a debt exists that was never recorded.
  Future<void> _openChangePayment(
      BuildContext context, AppLocalizations l10n) async {
    final bloc = context.read<HistoryBloc>();
    // Manager lock (Plan 016 B). Asked *before* the sheet, not after it: making
    // the shop fill in a correction and only then refusing it wastes the work
    // and reads as a bug.
    if (!await requireManager(context) || !mounted) return;
    if (!context.mounted) return;
    final choice = await showModalBottomSheet<_PaymentChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ChangePaymentSheet(invoice: _invoice),
    );
    if (choice == null || !mounted) return;

    _pendingChoice = choice;
    bloc.add(ChangeInvoicePaymentEvent(
        invoiceId: _invoice.id, customerId: choice.customerId));
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
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13)),
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
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant))),
      );
    }

    final borderColor = Theme.of(context).dividerColor;
    // Serial(م) · Item · Qty · Unit · Unit price · Total — the wholesale-invoice
    // layout the owner asked for (Plan 011 #10).
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
        2: IntrinsicColumnWidth(),
        3: IntrinsicColumnWidth(),
        4: IntrinsicColumnWidth(),
        5: IntrinsicColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(horizontalInside: BorderSide(color: borderColor)),
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          children: [
            _ivHead(l10n.colSerial, TextAlign.center),
            _ivHead(l10n.colProduct, TextAlign.start),
            _ivHead(l10n.colQty, TextAlign.center),
            _ivHead(l10n.colUnit, TextAlign.center),
            _ivHead(l10n.colUnitPrice, TextAlign.end),
            _ivHead(l10n.colTotal, TextAlign.end),
          ],
        ),
        for (final (i, item) in items.indexed)
          TableRow(
            children: [
              _ivCell('${i + 1}', TextAlign.center, subtitle: true),
              // Name (+ a small red per-line discount note when present).
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    // The IMEI/serial this line sold (Plan 012), replayed from
                    // the snapshot. This is what turns "which invoice sold this
                    // handset?" from unanswerable into one lookup.
                    if (item.serialSnapshot.isNotEmpty)
                      Text(
                        '${l10n.serialLabelShort}: ${item.serialSnapshot}',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    if (item.discount > 0)
                      Text(
                          '${l10n.discountLabel}: - ${_money(currency, item.discount)}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.red)),
                  ],
                ),
              ),
              _ivCell(formatQty(item.quantity), TextAlign.center),
              // Exact for any sale made since Plan 011 #10 (the line snapshots
              // its saleType); [InvoiceItem.isMeasured] falls back to the old
              // fractional-quantity guess only for older rows.
              _ivCell(
                item.isMeasured ? l10n.unitKg : l10n.unitPiece,
                TextAlign.center,
                subtitle: true,
              ),
              _ivCell(_money(currency, item.price), TextAlign.end,
                  subtitle: true),
              _ivCell(_money(currency, item.total), TextAlign.end, bold: true),
            ],
          ),
      ],
    );
  }

  Widget _ivHead(String label, TextAlign align) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Text(
          label,
          textAlign: align,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );

  Widget _ivCell(String text, TextAlign align,
          {bool bold = false, bool subtitle = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Text(
          text,
          textAlign: align,
          style: TextStyle(
            fontSize: subtitle ? 12 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: subtitle
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
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
        color: Theme.of(context).colorScheme.surface,
        border:
            Border(top: BorderSide(color: Theme.of(context).dividerColor)),
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
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color ?? Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }

  void _reprint(BuildContext context, String currency) {
    final shopState = context.read<ShopBloc>().state;
    final Shop shop = shopState is ShopLoaded ? shopState.shop : const Shop();
    context.read<HistoryBloc>().add(ReprintInvoiceEvent(
          invoiceId: _invoice.id,
          total: _invoice.total,
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
  /// Confirm deleting a sale (Plan 016 A).
  ///
  /// **The dialog lists the consequences, one line each, and it is not
  /// decoration.** Deleting a sale is not deleting a piece of paper: the goods
  /// go back into stock, the cash comes out of the drawer, and on a credit sale
  /// the customer's debt drops. A shopkeeper who expects only the invoice to
  /// disappear finds the drawer short at closing time and concludes the app
  /// lost their money — which is a far worse outcome than one extra dialog.
  ///
  /// Which lines show is decided per invoice: cash and credit undo different
  /// things, and naming the customer makes the debt line concrete.
  Future<void> _confirmDelete(BuildContext context, AppLocalizations l10n,
      InvoiceListItem inv, String currency) async {
    final bloc = context.read<HistoryBloc>();
    final customer = inv.customerName?.isNotEmpty == true
        ? inv.customerName!
        : l10n.paymentCredit;

    // Manager lock (Plan 016 B) — before the consequences dialog, so a helper
    // without the PIN is told "no" straight away rather than after reading a
    // warning they were never able to act on.
    if (!await requireManager(context) || !mounted) return;
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.deleteInvoiceTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteInvoiceIntro),
            const SizedBox(height: 12),
            _consequence(dialogCtx, Icons.inventory_2_outlined,
                l10n.deleteInvoiceStock),
            if (inv.isCredit)
              _consequence(dialogCtx, Icons.account_balance_wallet_outlined,
                  l10n.deleteInvoiceDebt(customer))
            else
              _consequence(dialogCtx, Icons.point_of_sale_outlined,
                  l10n.deleteInvoiceCash),
            const SizedBox(height: 12),
            Text(l10n.deleteInvoiceIrreversible,
                style: Theme.of(dialogCtx)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogCtx).colorScheme.error),
            onPressed: () {
              Navigator.pop(dialogCtx);
              bloc.add(DeleteInvoiceEvent(inv.id));
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Widget _consequence(BuildContext context, IconData icon, String text) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );

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

/// What the change-payment sheet pops: null [customerId] = cash, otherwise
/// credit for that customer. The name rides along purely so the caller can
/// repaint the header without waiting for a stream round-trip.
class _PaymentChoice {
  final String? customerId;
  final String? customerName;
  const _PaymentChoice({this.customerId, this.customerName});
}

/// Pick how an already-recorded sale was paid (Plan 016 C-a).
///
/// Deliberately **not** a two-line "cash or credit?" prompt. The sheet says
/// what moves and what does not, because the first question a shopkeeper asks
/// is whether editing an invoice will change the receipt their customer is
/// holding — and the answer, which is "no", is the reason this action exists
/// instead of delete-and-re-enter.
class _ChangePaymentSheet extends StatefulWidget {
  final InvoiceListItem invoice;
  const _ChangePaymentSheet({required this.invoice});

  @override
  State<_ChangePaymentSheet> createState() => _ChangePaymentSheetState();
}

class _ChangePaymentSheetState extends State<_ChangePaymentSheet> {
  late bool _isCredit;
  String? _customerId;
  String? _customerName;

  @override
  void initState() {
    super.initState();
    _isCredit = widget.invoice.isCredit;
    _customerId = widget.invoice.customerId;
    _customerName = widget.invoice.customerName;
  }

  Future<void> _pick() async {
    final picked = await pickCustomer(context);
    if (picked == null || !mounted) return;
    setState(() {
      _isCredit = true;
      _customerId = picked.id;
      _customerName = picked.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // Credit with nobody attached is not a payment record, it's a hole in one.
    final canSave = !_isCredit || _customerId != null;
    // Nothing to write, so Save would be a confusing no-op.
    final unchanged = _isCredit == widget.invoice.isCredit &&
        (!_isCredit || _customerId == widget.invoice.customerId);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(l10n.changePaymentTitle,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(l10n.changePaymentIntro,
                style: TextStyle(
                    fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 14),
            _option(
              selected: !_isCredit,
              icon: Icons.payments_outlined,
              title: l10n.paymentCash,
              subtitle: l10n.changePaymentCashHint,
              onTap: () => setState(() {
                _isCredit = false;
                _customerId = null;
                _customerName = null;
              }),
            ),
            const SizedBox(height: 8),
            _option(
              selected: _isCredit,
              icon: Icons.account_balance_wallet_outlined,
              title: _isCredit && (_customerName?.isNotEmpty ?? false)
                  ? '${l10n.paymentCredit} — $_customerName'
                  : l10n.paymentCredit,
              subtitle: l10n.changePaymentCreditHint,
              // Choosing credit is choosing *a customer* — there is no useful
              // in-between state, so the tap goes straight to the picker.
              onTap: _pick,
              trailing: _isCredit
                  ? TextButton(
                      onPressed: _pick,
                      child: Text(l10n.changePaymentChooseCustomer,
                          style: const TextStyle(fontSize: 12)))
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: 15, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(l10n.changePaymentNotRepayment,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: (!canSave || unchanged)
                        ? null
                        : () => Navigator.pop(
                              context,
                              _PaymentChoice(
                                customerId: _isCredit ? _customerId : null,
                                customerName: _isCredit ? _customerName : null,
                              ),
                            ),
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _option({
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.08) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? accent : theme.dividerColor,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color:
                    selected ? accent : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selected ? accent : null)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
