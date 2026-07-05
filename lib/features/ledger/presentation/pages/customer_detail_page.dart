import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/num_input.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../domain/entities/ledger_entry.dart';
import '../bloc/ledger_bloc.dart';
import '../customer_statement.dart';
import '../ledger_money.dart';

/// Map a [LedgerMessage] to a localized string.
String ledgerMessageText(LedgerMessage m, AppLocalizations l10n) {
  switch (m) {
    case LedgerMessage.chargeAdded:
      return l10n.debtAdded;
    case LedgerMessage.paymentAdded:
      return l10n.paymentRecorded;
    case LedgerMessage.entryDeleted:
      return l10n.entryDeleted;
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
            builder: (context, state) => IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: l10n.shareStatement,
              onPressed: (state.customer == null || state.entries.isEmpty)
                  ? null
                  : () => _shareStatement(context, state, l10n),
            ),
          ),
          BlocBuilder<LedgerBloc, LedgerState>(
            buildWhen: (p, c) => p.customer != c.customer,
            builder: (context, state) => IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: state.customer == null
                  ? null
                  : () => context.push('/settings/customers/edit/$customerId',
                      extra: state.customer),
            ),
          ),
        ],
      ),
      body: BlocConsumer<LedgerBloc, LedgerState>(
        listenWhen: (p, c) => c.message != null,
        listener: (context, state) {
          final isError = state.message == LedgerMessage.saveFailed ||
              state.message == LedgerMessage.loadFailed;
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
                    ? _empty(l10n)
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

  void _shareStatement(
      BuildContext context, LedgerState state, AppLocalizations l10n) {
    final shopState = context.read<ShopBloc>().state;
    final shopName = shopState is ShopLoaded ? shopState.shop.name : '';
    final text = buildCustomerStatement(
      l10n: l10n,
      shopName: shopName,
      customer: state.customer!,
      entries: state.entries,
      balance: state.balance,
      currency: currencyOf(context),
    );
    Share.share(text, subject: l10n.statementHeader(shopName));
  }

  Widget _balanceCard(
      BuildContext context, AppLocalizations l10n, double balance) {
    final settled = balance.abs() < 0.005;
    final owes = balance > 0;
    final color = settled
        ? Colors.grey
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

  Widget _empty(AppLocalizations l10n) {
    return Center(
      child: Text(l10n.noLedgerEntries,
          style: TextStyle(color: Colors.grey[500])),
    );
  }

  Widget _entryTile(
      BuildContext context, AppLocalizations l10n, LedgerEntry e) {
    final isPayment = e.type == LedgerEntryType.payment;
    final color = isPayment ? Colors.green.shade600 : Colors.red.shade600;
    final sign = isPayment ? '-' : '+';
    final date = DateFormat.yMMMd('ar').add_jm().format(e.createdAt);

    return ListTile(
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
      ),
      trailing: Text('$sign${moneyText(context, e.amount)}',
          style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      onLongPress: () => _confirmDelete(context, l10n, e),
    );
  }

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
