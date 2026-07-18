import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/money_display.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/cash_transaction.dart';
import '../../domain/entities/cash_transaction_type.dart';
import '../bloc/cashbox_bloc.dart';
import '../cashbox_labels.dart';

/// Full cash transaction history with Today / date-range / type filters. Reads
/// the app-wide [CashboxBloc].
class CashboxHistoryPage extends StatelessWidget {
  const CashboxHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cashHistoryTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
          final items = state.visibleTransactions;
          return Column(
            children: [
              _filterBar(context, l10n, state),
              const Divider(height: 1),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(l10n.noCashTransactions,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) =>
                            _txTile(context, l10n, items[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterBar(
      BuildContext context, AppLocalizations l10n, CashboxState state) {
    final bloc = context.read<CashboxBloc>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: Text(l10n.filterAll),
            selected: state.filterType == CashboxFilterType.all,
            onSelected: (_) =>
                bloc.add(const ChangeCashboxFilter(CashboxFilterType.all)),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(l10n.filterToday),
            selected: state.filterType == CashboxFilterType.today,
            onSelected: (_) =>
                bloc.add(const ChangeCashboxFilter(CashboxFilterType.today)),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(state.filterType == CashboxFilterType.dateRange &&
                    state.rangeStart != null &&
                    state.rangeEnd != null
                ? '${DateFormat.MMMd('ar').format(state.rangeStart!)} — ${DateFormat.MMMd('ar').format(state.rangeEnd!)}'
                : l10n.filterDateRange),
            selected: state.filterType == CashboxFilterType.dateRange,
            onSelected: (_) => _pickRange(context, bloc),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(state.filterType == CashboxFilterType.type &&
                    state.typeFilter != null
                ? cashTransactionTypeText(state.typeFilter!, l10n)
                : l10n.filterByType),
            selected: state.filterType == CashboxFilterType.type,
            onSelected: (_) => _pickType(context, l10n, bloc),
          ),
        ],
      ),
    );
  }

  Future<void> _pickRange(BuildContext context, CashboxBloc bloc) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (range != null) {
      bloc.add(ChangeCashboxFilter(
        CashboxFilterType.dateRange,
        rangeStart: range.start,
        rangeEnd: range.end,
      ));
    }
  }

  void _pickType(
      BuildContext context, AppLocalizations l10n, CashboxBloc bloc) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final type in CashTransactionType.values)
              ListTile(
                title: Text(cashTransactionTypeText(type, l10n)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  bloc.add(ChangeCashboxFilter(CashboxFilterType.type,
                      typeFilter: type));
                },
              ),
          ],
        ),
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
      onLongPress: () => _onLongPress(context, l10n, t),
    );
  }

  Future<void> _onLongPress(
      BuildContext context, AppLocalizations l10n, CashTransaction t) async {
    final bloc = context.read<CashboxBloc>();
    // System-generated entries can't be deleted here — they're reversed by
    // deleting their source sale / payment.
    if (t.isSystemGenerated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cashDeleteNotAllowed)),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cashDeleteTitle),
        content: Text(l10n.cashDeleteConfirm),
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
    if (ok == true) bloc.add(DeleteCashTransaction(t.id));
  }
}
