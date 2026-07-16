import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sales_invoices_table.dart';
import '../tables/sales_items_table.dart';
import '../tables/products_table.dart';
import '../tables/cashbox_transactions_table.dart';
import '../tables/ledger_entries_table.dart';
import '../tables/customers_table.dart';

part 'dashboard_dao.g.dart';

/// Read-only analytics aggregates for the Plan 008 dashboard. Everything is a
/// SQL aggregate (never load rows to sum in Dart) over the already-indexed
/// columns (`created_at`, `occurred_at`, `product_id`). All money stays
/// `double`, matching the rest of the app.
///
/// Whitelisted `ORDER BY` fragments only (never user input) — the repository
/// maps the product-metric toggle to one.
@DriftAccessor(tables: [
  SalesInvoices,
  SalesItems,
  Products,
  CashboxTransactions,
  LedgerEntries,
  Customers,
])
class DashboardDao extends DatabaseAccessor<AppDatabase>
    with _$DashboardDaoMixin {
  DashboardDao(super.db);

  /// A cheap "something changed" ticker so the dashboard reloads live after any
  /// sale / cash movement / debt entry / stock edit. `readsFrom` makes Drift
  /// re-emit whenever those tables change, even though the query is trivial.
  Stream<void> watchChanges() => customSelect(
        'SELECT 1',
        readsFrom: {
          salesInvoices,
          salesItems,
          cashboxTransactions,
          ledgerEntries,
          products,
        },
      ).watch().map((_) {});

  /// Revenue, estimated profit, and invoice count over a period. Profit uses the
  /// same correlated-subquery shape as `SalesDao.watchAuditSummary` (no fan-out).
  Future<PeriodTotalsRow> periodTotals(int fromMs, int toMs) async {
    final row = await customSelect(
      '''
SELECT COUNT(*) AS cnt,
       COALESCE(SUM(i.total_amount), 0.0) AS revenue,
       COALESCE(SUM(
         (SELECT COALESCE(SUM((si.price - si.cost) * si.quantity - si.discount), 0.0)
          FROM sales_items si WHERE si.invoice_id = i.id)
         - i.invoice_discount
       ), 0.0) AS profit
FROM sales_invoices i
WHERE i.created_at BETWEEN ? AND ?''',
      variables: [Variable.withInt(fromMs), Variable.withInt(toMs)],
      readsFrom: {salesInvoices, salesItems},
    ).getSingle();
    return PeriodTotalsRow(
      count: row.read<int>('cnt'),
      revenue: row.read<double>('revenue'),
      profit: row.read<double>('profit'),
    );
  }

  /// Raw (createdAt, total) stamps in a range — bucketed into local days by the
  /// repository (Dart), which sidesteps SQLite's UTC-vs-local day pitfalls.
  Future<List<InvoiceStampRow>> invoiceStamps(int fromMs, int toMs) async {
    final rows = await customSelect(
      'SELECT created_at, total_amount FROM sales_invoices '
      'WHERE created_at BETWEEN ? AND ? ORDER BY created_at ASC',
      variables: [Variable.withInt(fromMs), Variable.withInt(toMs)],
      readsFrom: {salesInvoices},
    ).get();
    return rows
        .map((r) => InvoiceStampRow(
              createdAt: r.read<int>('created_at'),
              total: r.read<double>('total_amount'),
            ))
        .toList();
  }

  /// Top products over a period. [orderByColumn] is a whitelisted metric column
  /// (`revenue` | `qty` | `profit`). Returns all three metrics per row so the UI
  /// can label whichever is selected.
  Future<List<TopProductRow>> topProducts(
    int fromMs,
    int toMs, {
    required String orderByColumn,
    int limit = 5,
  }) async {
    final rows = await customSelect(
      '''
SELECT si.product_id AS product_id,
       si.product_name AS product_name,
       COALESCE(SUM(si.quantity), 0.0) AS qty,
       COALESCE(SUM(si.price * si.quantity - si.discount), 0.0) AS revenue,
       COALESCE(SUM((si.price - si.cost) * si.quantity - si.discount), 0.0) AS profit
FROM sales_items si
JOIN sales_invoices i ON i.id = si.invoice_id
WHERE i.created_at BETWEEN ? AND ?
GROUP BY si.product_id, si.product_name
ORDER BY $orderByColumn DESC
LIMIT ?''',
      variables: [
        Variable.withInt(fromMs),
        Variable.withInt(toMs),
        Variable.withInt(limit),
      ],
      readsFrom: {salesItems, salesInvoices},
    ).get();
    return rows
        .map((r) => TopProductRow(
              productId: r.read<String>('product_id'),
              productName: r.read<String>('product_name'),
              quantity: r.read<double>('qty'),
              revenue: r.read<double>('revenue'),
              profit: r.read<double>('profit'),
            ))
        .toList();
  }

  /// Cash in / out and the two main outflow types over a period.
  Future<CashFlowRow> cashFlow(int fromMs, int toMs) async {
    final r = await customSelect(
      '''
SELECT COALESCE(SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END), 0.0) AS cash_in,
       COALESCE(SUM(CASE WHEN amount < 0 THEN -amount ELSE 0 END), 0.0) AS cash_out,
       COALESCE(SUM(CASE WHEN type = 'expense' THEN -amount ELSE 0 END), 0.0) AS expenses,
       COALESCE(SUM(CASE WHEN type = 'personalWithdrawal' THEN -amount ELSE 0 END), 0.0) AS withdrawals
FROM cashbox_transactions
WHERE occurred_at BETWEEN ? AND ?''',
      variables: [Variable.withInt(fromMs), Variable.withInt(toMs)],
      readsFrom: {cashboxTransactions},
    ).getSingle();
    return CashFlowRow(
      cashIn: r.read<double>('cash_in'),
      cashOut: r.read<double>('cash_out'),
      expenses: r.read<double>('expenses'),
      withdrawals: r.read<double>('withdrawals'),
    );
  }

  /// Current cash-drawer balance (all-time signed sum).
  Future<double> cashBalance() async {
    final r = await customSelect(
      'SELECT COALESCE(SUM(amount), 0.0) AS bal FROM cashbox_transactions',
      readsFrom: {cashboxTransactions},
    ).getSingle();
    return r.read<double>('bal');
  }

  /// Total outstanding customer debt (all-time net; charges − payments).
  Future<double> outstandingDebts() async {
    final r = await customSelect(
      "SELECT COALESCE(SUM(CASE WHEN entry_type = 'charge' THEN amount ELSE -amount END), 0.0) AS owed "
      'FROM ledger_entries',
      readsFrom: {ledgerEntries},
    ).getSingle();
    return r.read<double>('owed');
  }

  /// Inventory value on hand = Σ(quantity × cost).
  Future<double> inventoryValue() async {
    final r = await customSelect(
      'SELECT COALESCE(SUM(quantity * cost), 0.0) AS val FROM products',
      readsFrom: {products},
    ).getSingle();
    return r.read<double>('val');
  }

  /// Low-stock products (min alert set and on-hand at/under it), most urgent
  /// first. Lightweight projection — no need for the full Product entity.
  Future<List<NamedQtyRow>> lowStockProducts({int limit = 5}) async {
    final rows = await customSelect(
      'SELECT name, quantity FROM products '
      'WHERE min_stock_alert > 0 AND quantity <= min_stock_alert '
      'ORDER BY quantity ASC LIMIT ?',
      variables: [Variable.withInt(limit)],
      readsFrom: {products},
    ).get();
    return rows
        .map((r) => NamedQtyRow(
              name: r.read<String>('name'),
              value: r.read<double>('quantity'),
            ))
        .toList();
  }

  /// Customers with the highest outstanding balance (debtors), biggest first.
  Future<List<NamedQtyRow>> topDebtors({int limit = 5}) async {
    final rows = await customSelect(
      '''
SELECT c.name AS name,
       SUM(CASE WHEN le.entry_type = 'charge' THEN le.amount ELSE -le.amount END) AS balance
FROM ledger_entries le
JOIN customers c ON c.id = le.customer_id
GROUP BY le.customer_id, c.name
HAVING balance > 0.005
ORDER BY balance DESC
LIMIT ?''',
      variables: [Variable.withInt(limit)],
      readsFrom: {ledgerEntries, customers},
    ).get();
    return rows
        .map((r) => NamedQtyRow(
              name: r.read<String>('name'),
              value: r.read<double>('balance'),
            ))
        .toList();
  }
}

class PeriodTotalsRow {
  final int count;
  final double revenue;
  final double profit;
  const PeriodTotalsRow(
      {required this.count, required this.revenue, required this.profit});
}

class InvoiceStampRow {
  final int createdAt; // ms since epoch (local)
  final double total;
  const InvoiceStampRow({required this.createdAt, required this.total});
}

class TopProductRow {
  final String productId;
  final String productName;
  final double quantity;
  final double revenue;
  final double profit;
  const TopProductRow({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.revenue,
    required this.profit,
  });
}

class CashFlowRow {
  final double cashIn;
  final double cashOut;
  final double expenses;
  final double withdrawals;
  const CashFlowRow({
    required this.cashIn,
    required this.cashOut,
    required this.expenses,
    required this.withdrawals,
  });
}

/// Generic name + numeric value projection (low-stock qty, debtor balance).
class NamedQtyRow {
  final String name;
  final double value;
  const NamedQtyRow({required this.name, required this.value});
}
