import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/share/cards/customer_statement_share_card.dart';
import '../../../../core/share/share_card_action.dart';
import '../../../../core/share/share_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/num_input.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../billing/presentation/bloc/history_bloc.dart';
import '../../../shop/domain/entities/shop.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../domain/entities/ledger_entry.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/ledger_bloc.dart';
import '../customer_statement.dart';
import '../ledger_money.dart';
import 'customers_page.dart' show customerMessageText;

/// Which format the share menu asked for.
enum _ShareFormat { image, text }

/// Map a [LedgerMessage] to a localized string.
String ledgerMessageText(LedgerMessage m, AppLocalizations l10n) {
  switch (m) {
    case LedgerMessage.chargeAdded:
      return l10n.debtAdded;
    case LedgerMessage.paymentAdded:
      return l10n.paymentRecorded;
    case LedgerMessage.entryDeleted:
      return l10n.entryDeleted;
    case LedgerMessage.statementPrinted:
      return l10n.statementPrinted;
    case LedgerMessage.printerUnavailable:
      return l10n.printerUnavailable;
    case LedgerMessage.saveFailed:
      return l10n.ledgerSaveFailed;
    case LedgerMessage.loadFailed:
      return l10n.ledgerLoadFailed;
  }
}

class CustomerDetailPage extends StatelessWidget {
  final String customerId;
  const CustomerDetailPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<LedgerBloc, LedgerState>(
          buildWhen: (p, c) => p.customer != c.customer,
          builder: (context, state) => Text(
            state.customer?.name ?? l10n.customersTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        actions: [
          BlocBuilder<LedgerBloc, LedgerState>(
            buildWhen: (p, c) =>
                p.customer != c.customer || p.entries != c.entries,
            builder: (context, state) {
              final disabled =
                  state.customer == null || state.entries.isEmpty;
              return Row(children: [
                IconButton(
                  icon: const Icon(Icons.print_outlined),
                  tooltip: l10n.printStatement,
                  onPressed: disabled
                      ? null
                      : () => context
                          .read<LedgerBloc>()
                          .add(PrintStatement(_statementText(context, state, l10n))),
                ),
                // Image *and* text (Plan 013 #8). They are different tools, not
                // two versions of one: an image survives WhatsApp's formatting
                // and reads as a document the customer can show someone else;
                // text stays searchable and copyable. Customers ask for both.
                PopupMenuButton<_ShareFormat>(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: l10n.shareStatement,
                  enabled: !disabled,
                  onSelected: (format) => switch (format) {
                    _ShareFormat.image =>
                      _shareStatementImage(context, state, l10n),
                    _ShareFormat.text =>
                      _shareStatementText(context, state, l10n),
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _ShareFormat.image,
                      child: Row(children: [
                        const Icon(Icons.image_outlined, size: 20),
                        const SizedBox(width: 10),
                        Text(l10n.shareAsImage),
                      ]),
                    ),
                    PopupMenuItem(
                      value: _ShareFormat.text,
                      child: Row(children: [
                        const Icon(Icons.notes, size: 20),
                        const SizedBox(width: 10),
                        Text(l10n.shareAsText),
                      ]),
                    ),
                  ],
                ),
              ]);
            },
          ),
          BlocBuilder<LedgerBloc, LedgerState>(
            buildWhen: (p, c) => p.customer != c.customer,
            builder: (context, state) => IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: state.customer == null
                  ? null
                  : () => context.push('/customers/edit/$customerId',
                      extra: state.customer),
            ),
          ),
          // Delete is only offered once the account is settled (zero balance);
          // the repository still guards against dropping a customer who has
          // ledger history (archive instead).
          BlocBuilder<LedgerBloc, LedgerState>(
            buildWhen: (p, c) =>
                p.customer != c.customer || p.balance != c.balance,
            builder: (context, state) {
              final canDelete =
                  state.customer != null && state.balance.abs() < 0.005;
              if (!canDelete) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.delete,
                color: Colors.red.shade400,
                onPressed: () => _confirmDeleteCustomer(context, l10n),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<LedgerBloc, LedgerState>(
        listenWhen: (p, c) => c.message != null,
        listener: (context, state) {
          final isError = state.message == LedgerMessage.saveFailed ||
              state.message == LedgerMessage.loadFailed ||
              state.message == LedgerMessage.printerUnavailable;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ledgerMessageText(state.message!, l10n)),
            backgroundColor: isError ? Colors.red : Colors.green,
          ));
        },
        builder: (context, state) {
          return Column(
            children: [
              _balanceCard(context, l10n, state.balance),
              _actions(context, l10n),
              const Divider(height: 1),
              Expanded(
                child: state.entries.isEmpty
                    ? _empty(context, l10n)
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.entries.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) =>
                            _entryTile(context, l10n, state.entries[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build the localized statement text (shared by print & share so both emit
  /// identical content).
  String _statementText(
      BuildContext context, LedgerState state, AppLocalizations l10n) {
    final shopState = context.read<ShopBloc>().state;
    final shopName = shopState is ShopLoaded ? shopState.shop.name : '';
    return buildCustomerStatement(
      l10n: l10n,
      shopName: shopName,
      customer: state.customer!,
      entries: state.entries,
      balance: state.balance,
      currency: currencyOf(context),
    );
  }

  void _shareStatementText(
      BuildContext context, LedgerState state, AppLocalizations l10n) {
    final shopState = context.read<ShopBloc>().state;
    final shopName = shopState is ShopLoaded ? shopState.shop.name : '';
    ShareService.shareText(_statementText(context, state, l10n),
        subject: l10n.statementHeader(shopName));
  }

  /// The newest [_kMaxStatementRows] movements, oldest-first within that window.
  ///
  /// **Capped because the capture is a real image.** A two-year account can hold
  /// hundreds of entries, and `captureWidgetToPng` renders at `pixelRatio: 3.0`
  /// — the PNG becomes tall enough that some apps refuse to attach it, and the
  /// customer would be squinting at a strip. The **newest** are kept because
  /// that is what a debt conversation is about, and the count of what was left
  /// out is printed on the card: a silently truncated financial statement is
  /// worse than none, since the customer counts the rows and finds money
  /// missing.
  static const int _kMaxStatementRows = 30;

  Future<void> _shareStatementImage(
      BuildContext context, LedgerState state, AppLocalizations l10n) async {
    final shopState = context.read<ShopBloc>().state;
    final shopName = shopState is ShopLoaded ? shopState.shop.name : '';
    final currency = currencyOf(context);
    final customer = state.customer!;
    final df = DateFormat('yyyy/MM/dd', 'ar');

    // Oldest-first, matching the text statement — a running account only reads
    // correctly in the order it happened.
    final sorted = [...state.entries]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    var charges = 0.0;
    var payments = 0.0;
    for (final e in sorted) {
      if (e.type == LedgerEntryType.charge) {
        charges += e.amount;
      } else {
        payments += e.amount;
      }
    }

    // Totals above are over EVERY entry, never over the visible window — the
    // balance on the card must be the real balance.
    final omitted =
        sorted.length > _kMaxStatementRows ? sorted.length - _kMaxStatementRows : 0;
    final visible = sorted.skip(omitted).toList();

    final card = CustomerStatementShareCard(
      l10n: l10n,
      currency: currency,
      shopName: shopName,
      customerName: customer.name,
      customerPhone: customer.phone,
      dateText: df.format(DateTime.now()),
      omittedCount: omitted,
      lines: visible
          .map((e) => StatementShareLine(
                dateText: df.format(e.createdAt),
                label: e.type == LedgerEntryType.charge
                    ? l10n.entryDebt
                    : l10n.entryPayment,
                amount: e.amount,
                isCharge: e.type == LedgerEntryType.charge,
                note: e.note,
              ))
          .toList(),
      totalCharges: charges,
      totalPayments: payments,
      balance: state.balance,
    );

    await shareCardAsImage(context,
        card: card,
        fileName: 'statement_${customer.id}.png',
        messageText: shopName.isNotEmpty ? shopName : null);
  }

  Widget _balanceCard(
      BuildContext context, AppLocalizations l10n, double balance) {
    final settled = balance.abs() < 0.005;
    final owes = balance > 0;
    final color = settled
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : (owes ? Colors.red.shade600 : Colors.green.shade600);
    final label = settled
        ? l10n.balanceSettled
        : (owes ? l10n.balanceOwedLabel : l10n.balanceCreditLabel);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(moneyText(context, balance),
              style: TextStyle(
                  fontSize: 30, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () =>
                  _showEntrySheet(context, l10n, LedgerEntryType.payment),
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade600),
              icon: const Icon(Icons.south_west, size: 18),
              label: Text(l10n.recordPayment),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  _showEntrySheet(context, l10n, LedgerEntryType.charge),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade200),
              ),
              icon: const Icon(Icons.north_east, size: 18),
              label: Text(l10n.addDebt),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Text(l10n.noLedgerEntries,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }

  Widget _entryTile(
          BuildContext context, AppLocalizations l10n, LedgerEntry e) =>
      _EntryTile(
        entry: e,
        l10n: l10n,
        onDelete: () => _confirmDelete(context, l10n, e),
      );

  Future<void> _confirmDelete(
      BuildContext context, AppLocalizations l10n, LedgerEntry e) async {
    final bloc = context.read<LedgerBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteEntryTitle),
        content: Text(l10n.deleteEntryConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) bloc.add(DeleteLedgerEntry(e.id));
  }

  /// Delete the whole customer (only reachable when the balance is settled).
  /// Routed through the app-wide [CustomerBloc]; on success we leave the detail
  /// route, otherwise (e.g. the customer still has ledger history) we surface the
  /// localized reason.
  Future<void> _confirmDeleteCustomer(
      BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCustomerTitle),
        content: Text(l10n.deleteCustomerConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final bloc = context.read<CustomerBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    // Subscribe before dispatching so we don't miss the outcome.
    final outcome = bloc.stream.firstWhere((s) =>
        s.message == CustomerMessage.deleted ||
        s.message == CustomerMessage.deleteBlocked ||
        s.message == CustomerMessage.saveFailed);
    bloc.add(DeleteCustomer(customerId));
    final result = await outcome;

    if (result.message == CustomerMessage.deleted) {
      router.go('/customers');
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(customerMessageText(result.message!, l10n)),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showEntrySheet(
      BuildContext context, AppLocalizations l10n, LedgerEntryType type) {
    final bloc = context.read<LedgerBloc>();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isPayment = type == LedgerEntryType.payment;
    final accent = isPayment ? Colors.green.shade600 : Colors.red.shade600;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isPayment ? l10n.recordPayment : l10n.addDebt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountCtrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: NumInput.decimalFormatters,
                decoration: InputDecoration(
                  labelText: l10n.amountLabel,
                  prefixIcon: const Icon(Icons.payments_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = NumInput.parseFlexibleNumber(v);
                  if (n == null || n <= 0) return l10n.amountMustBePositive;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  labelText: l10n.noteOptional,
                  prefixIcon: const Icon(Icons.notes),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  final amount = NumInput.parseFlexibleNumber(amountCtrl.text)!;
                  bloc.add(AddLedgerEntry(LedgerEntry(
                    id: const Uuid().v4(),
                    customerId: customerId,
                    type: type,
                    amount: amount,
                    note: noteCtrl.text.trim(),
                    createdAt: DateTime.now(),
                  )));
                  Navigator.pop(sheetCtx);
                },
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row of a customer's account.
///
/// A **credit sale expands to show what was actually sold** (Plan 019 #1).
/// Before this, the account read "بيع آجل · 5,000" and stopped there: the shop
/// could see that someone owed 5,000 but not what for, and neither could the
/// customer standing at the counter. The link has always existed in the data
/// (`ledger_entries.invoiceId`) — it was simply never surfaced, so this costs
/// no schema and no new query.
///
/// Manual charges and payments have no invoice behind them and stay exactly as
/// they were, without a chevron promising something that cannot open.
class _EntryTile extends StatefulWidget {
  final LedgerEntry entry;
  final AppLocalizations l10n;
  final VoidCallback onDelete;

  const _EntryTile({
    required this.entry,
    required this.l10n,
    required this.onDelete,
  });

  @override
  State<_EntryTile> createState() => _EntryTileState();
}

class _EntryTileState extends State<_EntryTile> {
  bool _open = false;

  /// The lines are lazy-loaded and cached by the app-wide [HistoryBloc] — the
  /// same cache the invoice detail page fills. Sharing it means an invoice
  /// opened here is already loaded there, and a deleted sale drops out of both
  /// at once, because `_onDelete` evicts it.
  void _toggle() {
    final invoiceId = widget.entry.invoiceId;
    if (invoiceId == null) return;
    setState(() => _open = !_open);
    if (_open) {
      context.read<HistoryBloc>().add(LoadInvoiceDetailsEvent(invoiceId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final l10n = widget.l10n;
    final isPayment = e.type == LedgerEntryType.payment;
    final color = isPayment ? Colors.green.shade600 : Colors.red.shade600;
    final sign = isPayment ? '-' : '+';
    final date = DateFormat.yMMMd('ar').add_jm().format(e.createdAt);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(isPayment ? Icons.south_west : Icons.north_east,
                color: color, size: 20),
          ),
          title: Row(
            children: [
              Text(isPayment ? l10n.entryPayment : l10n.entryDebt,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (e.isFromSale) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(l10n.creditSaleTag,
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor)),
                ),
              ],
            ],
          ),
          subtitle: Text(
            e.note.isEmpty ? date : '$date · ${e.note}',
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$sign${moneyText(context, e.amount)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              // Only where there is something behind it. A chevron on a manual
              // charge would invite a tap that can lead nowhere.
              if (e.isFromSale)
                Icon(_open ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
          onTap: e.isFromSale ? _toggle : null,
          onLongPress: widget.onDelete,
        ),
        if (_open && e.invoiceId != null) _items(context, e.invoiceId!),
      ],
    );
  }

  Widget _items(BuildContext context, String invoiceId) {
    final l10n = widget.l10n;
    return BlocBuilder<HistoryBloc, HistoryState>(
      buildWhen: (p, c) =>
          p.itemsCache[invoiceId] != c.itemsCache[invoiceId] ||
          p.failedItems.contains(invoiceId) !=
              c.failedItems.contains(invoiceId),
      builder: (context, state) {
        final items = state.itemsCache[invoiceId];
        final failed = state.failedItems.contains(invoiceId);

        Widget body;
        if (items == null) {
          // Tapping retries: a failed load is recorded but never cached, so
          // re-requesting genuinely re-runs it.
          body = failed
              ? InkWell(
                  onTap: () => context
                      .read<HistoryBloc>()
                      .add(LoadInvoiceDetailsEvent(invoiceId)),
                  child: Text(l10n.itemsLoadFailed,
                      style: const TextStyle(fontSize: 12, color: Colors.red)),
                )
              : const Center(
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                );
        } else if (items.isEmpty) {
          body = Text(l10n.noItems,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant));
        } else {
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(item.productName,
                            style: const TextStyle(fontSize: 12.5)),
                      ),
                      const SizedBox(width: 8),
                      // Quantity × unit price, so a disputed line can be
                      // checked against the shelf price without opening the
                      // invoice itself.
                      Text(
                        '${formatQty(item.quantity)} × '
                        '${moneyText(context, item.price)}',
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 10),
                      Text(moneyText(context, item.total),
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              body,
              if (items != null && items.isNotEmpty) ...[
                const SizedBox(height: 4),
                // Reprint without leaving the account — this is the moment it
                // is wanted: the customer is disputing the amount, and the
                // answer is the original receipt.
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => _reprint(context, invoiceId),
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label:
                        Text(l10n.reprint, style: const TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _reprint(BuildContext context, String invoiceId) {
    final shopState = context.read<ShopBloc>().state;
    final shop = shopState is ShopLoaded ? shopState.shop : const Shop();
    context.read<HistoryBloc>().add(ReprintInvoiceEvent(
          invoiceId: invoiceId,
          // The charge's amount IS the invoice total — the sale path books it
          // as `amount = invoice total`. Re-summing the lines here would print
          // a pre-discount figure and disagree with the original receipt.
          total: widget.entry.amount,
          shopName: shop.name,
          address1: shop.addressLine1,
          address2: shop.addressLine2,
          phone: shop.phoneNumber,
          footer: shop.footerText,
          currency: currencyOf(context),
        ));
  }
}
