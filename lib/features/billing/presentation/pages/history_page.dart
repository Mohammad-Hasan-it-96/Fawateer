import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/share/cards/sales_summary_share_card.dart';
import '../../../../core/share/share_card_action.dart';
import '../../../dashboard/presentation/pages/dashboard_view.dart';
import '../../../shop/domain/entities/shop.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../domain/entities/invoice_list_item.dart';
import '../../domain/entities/sales_filter.dart';
import '../../domain/entities/sales_summary.dart';
import '../bloc/history_bloc.dart';
import '../../../../l10n/app_localizations.dart';

/// Format money the same way the rest of the app does: symbol then 2 decimals.
String _money(String currency, double v) => '$currency${v.toStringAsFixed(2)}';

/// The Sales History & Audit Center: a filterable, searchable list with a live
/// summary dashboard, sorting, and per-invoice reprint. Backed by [HistoryBloc]
/// (app-wide), whose list + summary streams re-filter reactively.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  /// The Reports sub-view: 0 = analytics dashboard (default), 1 = sales list.
  int _view = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<HistoryBloc>().add(LoadMoreEvent());
    }
  }

  void _apply(SalesFilter filter) =>
      context.read<HistoryBloc>().add(FilterChanged(filter));

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final filter = context.read<HistoryBloc>().state.filter;
      _apply(filter.withSearch(value.trim()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = (context.watch<ShopBloc>().state is ShopLoaded)
        ? (context.read<ShopBloc>().state as ShopLoaded).shop.currencySymbol
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportsTab,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Share the sales summary (Plan 007) — only on the Sales sub-view.
          if (_view == 1)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: l10n.shareAction,
              onPressed: () => _shareSummary(context, currency, l10n),
            ),
        ],
      ),
      body: Column(
        children: [
          _ViewToggle(
            index: _view,
            dashboardLabel: l10n.dashboardTab,
            salesLabel: l10n.salesTabLabel,
            onChanged: (i) => setState(() => _view = i),
          ),
          Expanded(
            child: _view == 0
                ? const DashboardView()
                : _salesView(context, l10n, currency),
          ),
        ],
      ),
    );
  }

  /// The original audit center (search + filters + summary + paginated list).
  Widget _salesView(
      BuildContext context, AppLocalizations l10n, String currency) {
    return BlocListener<HistoryBloc, HistoryState>(
      listenWhen: (prev, curr) =>
          prev.reprintStatus != curr.reprintStatus &&
          (curr.reprintStatus == ReprintStatus.done ||
              curr.reprintStatus == ReprintStatus.failed),
      listener: (context, state) {
        final ok = state.reprintStatus == ReprintStatus.done;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(ok ? l10n.printedSuccessfully : l10n.printFailed),
            backgroundColor: ok ? Colors.green : Colors.red,
          ));
      },
      child: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          return Column(
            children: [
              _SearchField(
                controller: _searchController,
                onChanged: _onSearchChanged,
              ),
              _FilterBar(filter: state.filter, onApply: _apply),
              _SummarySection(currency: currency, summary: state.summary),
              Expanded(child: _buildList(context, state, currency, l10n)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, HistoryState state, String currency,
      AppLocalizations l10n) {
    if (state.status == HistoryStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == HistoryStatus.error) {
      return Center(
        child: Text(l10n.historyLoadFailed,
            style: const TextStyle(color: Colors.red)),
      );
    }
    if (state.invoices.isEmpty) {
      return _EmptyState(filter: state.filter);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: state.invoices.length + (state.loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.invoices.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final item = state.invoices[index];
        return _InvoiceCard(
          item: item,
          currency: currency,
          reprinting: state.reprintStatus == ReprintStatus.printing &&
              state.reprintingId == item.id,
          onTap: () => context.push('/history/detail/${item.id}', extra: item),
          onReprint: () => _reprint(context, item, currency),
        );
      },
    );
  }

  /// Share the current filter's sales summary as a styled PNG (Plan 007).
  Future<void> _shareSummary(
      BuildContext context, String currency, AppLocalizations l10n) async {
    final histState = context.read<HistoryBloc>().state;
    final shopState = context.read<ShopBloc>().state;
    final shopName = shopState is ShopLoaded ? shopState.shop.name : '';
    final locale = Localizations.localeOf(context).toString();
    final s = histState.summary;
    final card = SalesSummaryShareCard(
      l10n: l10n,
      currency: currency,
      shopName: shopName,
      periodText: _periodText(histState.filter, locale, l10n),
      count: s.count,
      total: s.total,
      cashTotal: s.cashTotal,
      creditTotal: s.creditTotal,
      average: s.average,
      profit: s.profit,
    );
    await shareCardAsImage(context,
        card: card,
        fileName: 'sales_summary.png',
        messageText: shopName.isNotEmpty ? shopName : null);
  }

  /// Human label for the filter's period (preset name, or a custom date range).
  String _periodText(SalesFilter f, String locale, AppLocalizations l10n) {
    switch (f.preset) {
      case DatePreset.today:
        return l10n.filterToday;
      case DatePreset.yesterday:
        return l10n.filterYesterday;
      case DatePreset.last7Days:
        return l10n.filterLast7Days;
      case DatePreset.last30Days:
        return l10n.filterLast30Days;
      case DatePreset.thisWeek:
        return l10n.filterThisWeek;
      case DatePreset.thisMonth:
        return l10n.filterThisMonth;
      case DatePreset.custom:
        final df = DateFormat.yMMMd(locale);
        return '${df.format(f.from)} – ${df.format(f.to)}';
    }
  }

  void _reprint(BuildContext context, InvoiceListItem item, String currency) {
    final shopState = context.read<ShopBloc>().state;
    final Shop shop =
        shopState is ShopLoaded ? shopState.shop : const Shop();
    context.read<HistoryBloc>().add(ReprintInvoiceEvent(
          invoiceId: item.id,
          total: item.total,
          shopName: shop.name,
          address1: shop.addressLine1,
          address2: shop.addressLine2,
          phone: shop.phoneNumber,
          footer: shop.footerText,
          currency: currency,
        ));
  }
}

/// Segmented switch between the analytics dashboard and the sales list.
class _ViewToggle extends StatelessWidget {
  final int index;
  final String dashboardLabel;
  final String salesLabel;
  final ValueChanged<int> onChanged;
  const _ViewToggle({
    required this.index,
    required this.dashboardLabel,
    required this.salesLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
                value: 0,
                icon: const Icon(Icons.insights, size: 18),
                label: Text(dashboardLabel)),
            ButtonSegment(
                value: 1,
                icon: const Icon(Icons.receipt_long, size: 18),
                label: Text(salesLabel)),
          ],
          selected: {index},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ),
    );
  }
}

/// Search box (invoice # or customer name). Debounced by the parent.
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.searchInvoicesHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          isDense: true,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/// Date presets, payment filter, and sort — all applied through [onApply].
class _FilterBar extends StatelessWidget {
  final SalesFilter filter;
  final ValueChanged<SalesFilter> onApply;
  const _FilterBar({required this.filter, required this.onApply});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        // Row 1: date presets.
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _chip(l10n.filterToday, filter.preset == DatePreset.today,
                  () => onApply(filter.withPreset(DatePreset.today))),
              _chip(l10n.filterYesterday, filter.preset == DatePreset.yesterday,
                  () => onApply(filter.withPreset(DatePreset.yesterday))),
              _chip(l10n.filterThisWeek, filter.preset == DatePreset.thisWeek,
                  () => onApply(filter.withPreset(DatePreset.thisWeek))),
              _chip(l10n.filterThisMonth, filter.preset == DatePreset.thisMonth,
                  () => onApply(filter.withPreset(DatePreset.thisMonth))),
              _chip(
                _customLabel(context, l10n),
                filter.preset == DatePreset.custom,
                () => _pickRange(context),
                icon: Icons.date_range,
              ),
            ],
          ),
        ),
        // Row 2: payment filter + sort.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            children: [
              _chip(l10n.filterAll, filter.payment == PaymentFilter.all,
                  () => onApply(filter.withPayment(PaymentFilter.all))),
              _chip(l10n.paymentCash, filter.payment == PaymentFilter.cash,
                  () => onApply(filter.withPayment(PaymentFilter.cash))),
              _chip(l10n.paymentCredit, filter.payment == PaymentFilter.credit,
                  () => onApply(filter.withPayment(PaymentFilter.credit))),
              const Spacer(),
              _sortButton(context, l10n),
            ],
          ),
        ),
      ],
    );
  }

  String _customLabel(BuildContext context, AppLocalizations l10n) {
    if (filter.preset != DatePreset.custom) return l10n.filterDateRange;
    final locale = Localizations.localeOf(context).toString();
    final f = DateFormat.MMMd(locale);
    return '${f.format(filter.from)} – ${f.format(filter.to)}';
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: DateTimeRange(start: filter.from, end: filter.to)
          .clampWithin(DateTime(2020), now),
    );
    if (picked != null) {
      onApply(filter.withCustomRange(picked.start, picked.end));
    }
  }

  Widget _sortButton(BuildContext context, AppLocalizations l10n) {
    String label(SalesSort s) => switch (s) {
          SalesSort.newest => l10n.sortNewest,
          SalesSort.oldest => l10n.sortOldest,
          SalesSort.highest => l10n.sortHighest,
          SalesSort.lowest => l10n.sortLowest,
        };
    return PopupMenuButton<SalesSort>(
      initialValue: filter.sort,
      onSelected: (s) => onApply(filter.withSort(s)),
      itemBuilder: (_) => [
        for (final s in SalesSort.values)
          PopupMenuItem(value: s, child: Text(label(s))),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sort, size: 18),
          const SizedBox(width: 4),
          Text(label(filter.sort),
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap,
      {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        showCheckmark: false,
        avatar: icon != null ? Icon(icon, size: 16) : null,
        label: Text(label),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

/// Summary dashboard: a hero card (total + count) plus cash / credit / average.
class _SummarySection extends StatelessWidget {
  final String currency;
  final SalesSummary summary;
  const _SummarySection({required this.currency, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.summaryTotal,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_money(currency, summary.total),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${summary.count}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                    Text(l10n.summaryInvoices,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: l10n.summaryCash,
                  value: _money(currency, summary.cashTotal),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: l10n.summaryCredit,
                  value: _money(currency, summary.creditTotal),
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: l10n.summaryAverage,
                  value: _money(currency, summary.average),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ),
        ],
      ),
    );
  }
}

/// One invoice row: date/time, customer + payment badge, item count, total,
/// and a reprint action. Tapping opens the detail page.
class _InvoiceCard extends StatelessWidget {
  final InvoiceListItem item;
  final String currency;
  final bool reprinting;
  final VoidCallback onTap;
  final VoidCallback onReprint;

  const _InvoiceCard({
    required this.item,
    required this.currency,
    required this.reprinting,
    required this.onTap,
    required this.onReprint,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final dateStr =
        DateFormat.yMMMd(locale).add_jm().format(item.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateStr,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _PaymentBadge(
                            isCredit: item.isCredit,
                            customerName: item.customerName),
                        const SizedBox(width: 8),
                        Text(l10n.itemCountLabel(item.itemCount),
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_money(currency, item.total),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  reprinting
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.print_outlined, size: 20),
                          tooltip: l10n.reprint,
                          onPressed: onReprint,
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  final bool isCredit;
  final String? customerName;
  const _PaymentBadge({required this.isCredit, this.customerName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = isCredit ? Colors.orange : Colors.green;
    final label = isCredit
        ? (customerName?.isNotEmpty == true
            ? customerName!
            : l10n.paymentCredit)
        : l10n.paymentCash;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isCredit ? Icons.person_outline : Icons.payments_outlined,
              size: 13, color: color),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final SalesFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final narrowed = filter.search.isNotEmpty ||
        filter.payment != PaymentFilter.all ||
        filter.preset != DatePreset.today;
    // Scroll-and-center, never a bare Center: the search field, the filter
    // chips and the summary cards above this can leave under 150px on a small
    // phone, and a fixed Column then overflows (reported from a device: "bottom
    // overflowed by 43 pixels" striped over the empty sales list). Centered
    // while it fits, scrollable the moment it doesn't.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 24).clamp(0.0, double.infinity)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.receipt_long,
                    size: 40,
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
              const SizedBox(height: 16),
              Text(narrowed ? l10n.noSalesMatch : l10n.noSalesYet,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              if (!narrowed) ...[
                const SizedBox(height: 8),
                Text(l10n.noSalesHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Clamp a [DateTimeRange] so its bounds fall within [min]/[max]. Guards the
/// date-range picker against a saved custom range that predates [min].
extension _ClampRange on DateTimeRange {
  DateTimeRange clampWithin(DateTime min, DateTime max) {
    final s = start.isBefore(min) ? min : (start.isAfter(max) ? max : start);
    final e = end.isAfter(max) ? max : (end.isBefore(s) ? s : end);
    return DateTimeRange(start: s, end: e);
  }
}
