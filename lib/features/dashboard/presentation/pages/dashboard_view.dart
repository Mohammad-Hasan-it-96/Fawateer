import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/money_display.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../attributes/domain/entities/attribute_definition.dart';
import '../../../attributes/presentation/bloc/attribute_definition_bloc.dart';
import '../../../billing/domain/entities/sales_filter.dart';
import '../../domain/entities/dashboard_data.dart';
import '../bloc/dashboard_bloc.dart';
import '../dashboard_format.dart';
import '../widgets/cash_flow_card.dart';
import '../widgets/kpi_card.dart';
import '../widgets/mini_list_card.dart';
import '../widgets/section_card.dart';
import '../widgets/sales_trend_chart.dart';
import '../widgets/top_products_chart.dart';

/// The analytics dashboard (Plan 008, lean V1). A single scrollable screen:
/// time-range filter → business-health KPIs → sales trend → top products →
/// cash flow → low-stock & top-debtor mini-lists. Reads the route-scoped
/// [DashboardBloc]; currency comes from the app-wide ShopBloc.
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = currencyOf(context);
    final locale = Localizations.localeOf(context).toString();

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final d = state.data;
        return Column(
          children: [
            _RangeBar(filter: state.filter),
            if (state.status == DashboardStatus.loading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else if (state.status == DashboardStatus.error)
              Expanded(
                child: Center(
                  child: Text(l10n.dashboardLoadFailed,
                      style: const TextStyle(color: Colors.red)),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _kpiGrid(context, l10n, currency, d),
                    const SizedBox(height: 12),
                    SectionCard(
                      title: l10n.salesTrendTitle,
                      child: SalesTrendChart(
                          buckets: d.salesTrend, locale: locale),
                    ),
                    SectionCard(
                      title: l10n.topProductsTitle,
                      trailing: _MetricToggle(metric: state.metric),
                      child: TopProductsChart(
                        products: d.topProducts,
                        metric: state.metric,
                        currency: currency,
                        emptyText: l10n.dashboardNoData,
                      ),
                    ),
                    _SalesByFieldSection(
                        state: state, currency: currency, l10n: l10n),
                    SectionCard(
                      title: l10n.cashFlowTitle,
                      child: CashFlowCard(
                        l10n: l10n,
                        currency: currency,
                        cashIn: d.cashIn,
                        cashOut: d.cashOut,
                        expenses: d.expenses,
                        withdrawals: d.withdrawals,
                      ),
                    ),
                    SectionCard(
                      title: l10n.lowStockTitle,
                      child: MiniListCard(
                        items: d.lowStock,
                        format: qtyCompact,
                        amountColor: Colors.orange.shade700,
                        leadingIcon: Icons.inventory_2_outlined,
                        emptyText: l10n.dashboardNoData,
                        onTap: (_) => context.go('/products'),
                      ),
                    ),
                    SectionCard(
                      title: l10n.topDebtorsTitle,
                      child: MiniListCard(
                        items: d.topDebtors,
                        format: (v) => moneyCompact(currency, v),
                        amountColor: Colors.red.shade600,
                        leadingIcon: Icons.person_outline,
                        emptyText: l10n.dashboardNoData,
                        onTap: (_) => context.go('/customers'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _kpiGrid(BuildContext context, AppLocalizations l10n, String currency,
      DashboardData d) {
    final cardW = (MediaQuery.of(context).size.width - 32 - 12) / 2;
    Widget wrap(Widget card) => SizedBox(width: cardW, child: card);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        wrap(KpiCard(
          label: l10n.revenueLabel,
          value: moneyCompact(currency, d.revenue),
          icon: Icons.point_of_sale,
          accent: Colors.blue.shade600,
          deltaPct: d.revenueDeltaPct,
        )),
        wrap(KpiCard(
          label: l10n.estimatedProfit,
          value: moneyCompact(currency, d.profit),
          icon: Icons.trending_up,
          accent: Colors.green.shade600,
          deltaPct: d.profitDeltaPct,
        )),
        wrap(KpiCard(
          label: l10n.cashboxBalanceLabel,
          value: moneyCompact(currency, d.cashBalance),
          icon: Icons.account_balance_wallet_outlined,
          accent: Colors.teal.shade600,
        )),
        wrap(KpiCard(
          label: l10n.outstandingDebtsLabel,
          value: moneyCompact(currency, d.outstandingDebts),
          icon: Icons.receipt_long_outlined,
          accent: Colors.red.shade600,
        )),
        wrap(KpiCard(
          label: l10n.inventoryValueLabel,
          value: moneyCompact(currency, d.inventoryValue),
          icon: Icons.inventory_2_outlined,
          accent: Colors.deepPurple.shade400,
        )),
      ],
    );
  }
}

/// Horizontal time-range chips. Reuses [SalesFilter]'s presets (+ Last 7/30) so
/// the ranges match the audit center exactly.
class _RangeBar extends StatelessWidget {
  final SalesFilter filter;
  const _RangeBar({required this.filter});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    void apply(SalesFilter f) =>
        context.read<DashboardBloc>().add(DashboardRangeChanged(f));

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _chip(l10n.filterToday, filter.preset == DatePreset.today,
              () => apply(filter.withPreset(DatePreset.today))),
          _chip(l10n.filterYesterday, filter.preset == DatePreset.yesterday,
              () => apply(filter.withPreset(DatePreset.yesterday))),
          _chip(l10n.filterLast7Days, filter.preset == DatePreset.last7Days,
              () => apply(filter.withPreset(DatePreset.last7Days))),
          _chip(l10n.filterLast30Days, filter.preset == DatePreset.last30Days,
              () => apply(filter.withPreset(DatePreset.last30Days))),
          _chip(l10n.filterThisMonth, filter.preset == DatePreset.thisMonth,
              () => apply(filter.withPreset(DatePreset.thisMonth))),
          _chip(_customLabel(context, l10n),
              filter.preset == DatePreset.custom, () => _pickRange(context),
              icon: Icons.date_range),
        ],
      ),
    );
  }

  String _customLabel(BuildContext context, AppLocalizations l10n) {
    if (filter.preset != DatePreset.custom) return l10n.filterDateRange;
    final f = MaterialLocalizations.of(context);
    return '${f.formatShortDate(filter.from)} – ${f.formatShortDate(filter.to)}';
  }

  Future<void> _pickRange(BuildContext context) async {
    final bloc = context.read<DashboardBloc>();
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: DateTimeRange(start: filter.from, end: filter.to),
    );
    if (picked != null) {
      bloc.add(DashboardRangeChanged(
          filter.withCustomRange(picked.start, picked.end)));
    }
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

/// "Sales by field" report (Plan 010): break sales down by a custom product
/// field's values, reusing the top-products ranked bars + the current metric.
/// Hidden entirely when the shop has defined no custom fields.
class _SalesByFieldSection extends StatelessWidget {
  final DashboardState state;
  final String currency;
  final AppLocalizations l10n;
  const _SalesByFieldSection(
      {required this.state, required this.currency, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final defs = context.watch<AttributeDefinitionBloc>().state.active;
    if (defs.isEmpty) return const SizedBox.shrink();
    // Drop a stale selection if that field was archived/deleted meanwhile.
    final selectedId =
        defs.any((d) => d.id == state.selectedFieldId) ? state.selectedFieldId : null;

    return SectionCard(
      title: l10n.salesByFieldTitle,
      trailing: _ReportFieldSelector(defs: defs, selectedId: selectedId),
      child: selectedId == null
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(l10n.salesByFieldHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13)),
              ),
            )
          : TopProductsChart(
              products: state.attributeBreakdown,
              metric: state.metric,
              currency: currency,
              emptyText: l10n.dashboardNoData,
            ),
    );
  }
}

/// Dropdown to pick which custom field the "Sales by field" report groups by
/// (or turn it off).
class _ReportFieldSelector extends StatelessWidget {
  final List<AttributeDefinition> defs;
  final String? selectedId;
  const _ReportFieldSelector({required this.defs, required this.selectedId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButton<String?>(
      value: selectedId,
      isDense: true,
      underline: const SizedBox.shrink(),
      hint: Text(l10n.reportFieldNone,
          style: Theme.of(context).textTheme.labelMedium),
      style: Theme.of(context).textTheme.labelLarge,
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.reportFieldNone)),
        for (final d in defs)
          DropdownMenuItem(value: d.id, child: Text(d.label)),
      ],
      onChanged: (id) =>
          context.read<DashboardBloc>().add(SelectReportField(id)),
    );
  }
}

/// Revenue / quantity / profit toggle for the top-products chart.
class _MetricToggle extends StatelessWidget {
  final ProductMetric metric;
  const _MetricToggle({required this.metric});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<ProductMetric>(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
            Theme.of(context).textTheme.labelSmall),
      ),
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
            value: ProductMetric.revenue, label: Text(l10n.revenueLabel)),
        ButtonSegment(
            value: ProductMetric.quantity, label: Text(l10n.metricQuantity)),
        ButtonSegment(
            value: ProductMetric.profit, label: Text(l10n.metricProfit)),
      ],
      selected: {metric},
      onSelectionChanged: (s) =>
          context.read<DashboardBloc>().add(DashboardMetricChanged(s.first)),
    );
  }
}
