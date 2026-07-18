import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/share/cards/cashbox_summary_share_card.dart';
import '../../../../core/share/share_card_action.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_display.dart';
import '../../../../core/utils/num_input.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../domain/entities/cash_transaction.dart';
import '../../domain/entities/cash_transaction_type.dart';
import '../bloc/cashbox_bloc.dart';
import '../cashbox_labels.dart';

/// Main cashbox screen: current balance, today's cash-in / cash-out, quick
/// actions, and a short recent-activity preview. Reads the app-wide
/// [CashboxBloc].
class CashboxPage extends StatelessWidget {
  const CashboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cashboxTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: l10n.shareAction,
            onPressed: () => _shareDailySummary(context, l10n),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.addCashTransaction,
            onPressed: () => _showTypePicker(context, l10n),
          ),
        ],
      ),
      body: BlocConsumer<CashboxBloc, CashboxState>(
        listenWhen: (p, c) => c.message != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(cashboxMessageText(state.message!, l10n)),
            backgroundColor: cashboxMessageIsError(state.message!)
                ? Colors.red
                : Colors.green,
          ));
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _balanceCard(context, l10n, state.balance),
              _todayRow(context, l10n, state.todayIn, state.todayOut),
              const SizedBox(height: 8),
              _quickActions(context, l10n),
              const SizedBox(height: 8),
              const Divider(height: 1),
              _recentHeader(context, l10n),
              if (state.transactions.isEmpty)
                _empty(context, l10n)
              else
                ...state.transactions
                    .take(5)
                    .map((t) => _txTile(context, l10n, t)),
            ],
          );
        },
      ),
    );
  }

  Widget _balanceCard(
      BuildContext context, AppLocalizations l10n, double balance) {
    final positive = balance >= 0;
    final color = positive ? AppTheme.primaryColor : Colors.red.shade600;
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
          Text(l10n.cashboxBalanceLabel,
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

  Widget _todayRow(BuildContext context, AppLocalizations l10n, double inSum,
      double outSum) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _statCard(context, l10n.todayCashIn, inSum,
                Colors.green.shade600, Icons.south_west),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(context, l10n.todayCashOut, outSum,
                Colors.red.shade600, Icons.north_east),
          ),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, double amount,
      Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(moneyText(context, amount),
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _action(context, Icons.add_card, l10n.addDeposit, Colors.green.shade600,
              () => _showEntrySheet(context, l10n, CashTransactionType.manualDeposit)),
          _action(context, Icons.remove_circle_outline, l10n.withdrawMoney,
              Colors.orange.shade700,
              () => _showEntrySheet(context, l10n, CashTransactionType.personalWithdrawal)),
          _action(context, Icons.receipt_long, l10n.addExpense, Colors.red.shade600,
              () => _showEntrySheet(context, l10n, CashTransactionType.expense)),
          _action(context, Icons.history, l10n.viewHistory, AppTheme.primaryColor,
              () => context.push('/settings/cashbox/history')),
        ],
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String label, Color color,
      VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
      child: Row(
        children: [
          Text(l10n.recentTransactions,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const Spacer(),
          TextButton(
            onPressed: () => context.push('/settings/cashbox/history'),
            child: Text(l10n.viewHistory),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(l10n.noCashTransactions,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
    );
  }

  Widget _txTile(
      BuildContext context, AppLocalizations l10n, CashTransaction t) {
    final color = t.isInflow ? Colors.green.shade600 : Colors.red.shade600;
    final sign = t.isInflow ? '+' : '-';
    final date = DateFormat.yMMMd('ar').add_jm().format(t.occurredAt);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(t.isInflow ? Icons.south_west : Icons.north_east,
            color: color, size: 20),
      ),
      title: Text(cashTransactionTypeText(t.type, l10n),
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(t.note.isEmpty ? date : '$date · ${t.note}',
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      trailing: Text('$sign${moneyText(context, t.magnitude)}',
          style: TextStyle(fontWeight: FontWeight.bold, color: color)),
    );
  }

  /// Share today's cashbox summary as a styled PNG (Plan 007). Everything is
  /// derived from the already-streamed transactions — opening balance is the
  /// current balance minus today's net movement.
  Future<void> _shareDailySummary(
      BuildContext context, AppLocalizations l10n) async {
    final state = context.read<CashboxBloc>().state;
    final shopState = context.read<ShopBloc>().state;
    final shopName = shopState is ShopLoaded ? shopState.shop.name : '';
    final currency =
        shopState is ShopLoaded ? shopState.shop.currencySymbol : '';
    final locale = Localizations.localeOf(context).toString();

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final todayTx = state.transactions
        .where((t) =>
            !t.occurredAt.isBefore(start) && t.occurredAt.isBefore(end))
        .toList();

    // Net signed sum per type → one breakdown row each.
    final byType = <CashTransactionType, double>{};
    for (final t in todayTx) {
      byType[t.type] = (byType[t.type] ?? 0) + t.amount;
    }
    final breakdown = byType.entries
        .where((e) => e.value.abs() > 0.005)
        .map((e) => CashboxBreakdownRow(
              label: cashTransactionTypeText(e.key, l10n),
              amount: e.value.abs(),
              isInflow: e.value >= 0,
            ))
        .toList();

    final closing = state.balance;
    final opening = closing - (state.todayIn - state.todayOut);

    final card = CashboxSummaryShareCard(
      l10n: l10n,
      currency: currency,
      shopName: shopName,
      dateText: DateFormat.yMMMd(locale).format(now),
      opening: opening,
      closing: closing,
      totalIn: state.todayIn,
      totalOut: state.todayOut,
      breakdown: breakdown,
    );
    await shareCardAsImage(context,
        card: card,
        fileName: 'cashbox_summary.png',
        messageText: shopName.isNotEmpty ? shopName : null);
  }

  /// Pick a manual transaction type (deposit, expense, withdrawal, opening
  /// balance, adjustment), then open the entry sheet.
  void _showTypePicker(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.selectType,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            for (final type in CashTransactionType.manualTypes)
              ListTile(
                leading: Icon(_typeIcon(type)),
                title: Text(cashTransactionTypeText(type, l10n)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showEntrySheet(context, l10n, type);
                },
              ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(CashTransactionType type) {
    switch (type) {
      case CashTransactionType.manualDeposit:
        return Icons.add_card;
      case CashTransactionType.expense:
        return Icons.receipt_long;
      case CashTransactionType.personalWithdrawal:
        return Icons.remove_circle_outline;
      case CashTransactionType.openingBalance:
        return Icons.account_balance_wallet_outlined;
      case CashTransactionType.manualAdjustment:
        return Icons.tune;
      default:
        return Icons.payments_outlined;
    }
  }

  /// Entry form for a manual cash transaction of [type]. For an adjustment
  /// (bidirectional) an in/out toggle is shown; other types have a fixed sign.
  void _showEntrySheet(
      BuildContext context, AppLocalizations l10n, CashTransactionType type) {
    final bloc = context.read<CashboxBloc>();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isAdjustment = type.defaultDirection == CashDirection.either;
    // For an adjustment, default the toggle to inflow.
    CashDirection chosen =
        isAdjustment ? CashDirection.inflow : type.defaultDirection;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
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
                Text(cashTransactionTypeText(type, l10n),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (isAdjustment) ...[
                  SegmentedButton<CashDirection>(
                    segments: [
                      ButtonSegment(
                          value: CashDirection.inflow,
                          icon: const Icon(Icons.south_west, size: 16),
                          label: Text(l10n.cashInflow)),
                      ButtonSegment(
                          value: CashDirection.outflow,
                          icon: const Icon(Icons.north_east, size: 16),
                          label: Text(l10n.cashOutflow)),
                    ],
                    selected: {chosen},
                    onSelectionChanged: (s) =>
                        setSheetState(() => chosen = s.first),
                  ),
                  const SizedBox(height: 12),
                ],
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
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final magnitude =
                        NumInput.parseFlexibleNumber(amountCtrl.text)!;
                    final signed = chosen == CashDirection.outflow
                        ? -magnitude
                        : magnitude;
                    final now = DateTime.now();
                    bloc.add(AddCashTransaction(CashTransaction(
                      id: const Uuid().v4(),
                      type: type,
                      amount: signed,
                      note: noteCtrl.text.trim(),
                      occurredAt: now,
                      createdAt: now,
                    )));
                    Navigator.pop(sheetCtx);
                  },
                  child: Text(l10n.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
