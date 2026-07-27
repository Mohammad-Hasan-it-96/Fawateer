import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sales_invoices_table.dart';
import '../tables/sales_items_table.dart';
import '../tables/ledger_entries_table.dart';
import '../tables/cashbox_transactions_table.dart';
import '../tables/customers_table.dart';
import '../tables/products_table.dart';
import '../tables/product_units_table.dart';

part 'sales_dao.g.dart';

@DriftAccessor(tables: [
  SalesInvoices,
  SalesItems,
  LedgerEntries,
  CashboxTransactions,
  Customers,
  // Not selected from here — declared so the stock deduction below can name it
  // as an updated table, which is what re-runs `watchAllProducts`.
  Products,
  // Serialized units consumed by a sale are marked sold in the sale's own
  // transaction (Plan 012).
  ProductUnits,
])
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(super.db);

  /// All invoices ordered by newest first.
  Future<List<SalesInvoiceRow>> getAllInvoices() =>
      (select(salesInvoices)
            ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
          .get();

  /// Reactive stream of all invoices.
  Stream<List<SalesInvoiceRow>> watchAllInvoices() =>
      (select(salesInvoices)
            ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
          .watch();

  /// All line items belonging to a specific invoice.
  Future<List<SalesItemRow>> getItemsForInvoice(String invoiceId) =>
      (select(salesItems)..where((i) => i.invoiceId.equals(invoiceId))).get();

  // ── Audit center (filtered list + summary) ─────────────────────────────────
  //
  // `sales_invoices` is intentionally minimal (id, created_at, total_amount).
  // Payment type and customer are *derived*: an invoice is CREDIT iff a
  // `ledger_entries` `charge` row references it (that row also carries the
  // customer); otherwise it's a CASH (anonymous) sale. So both queries LEFT
  // JOIN the ledger (one charge row per invoice at most → no fan-out) and the
  // customer. Reactive via `.watch()` with an explicit `readsFrom` so they
  // re-emit after every new sale. Indexes already back these: created_at,
  // sales_items.invoice_id, ledger_entries.invoice_id.

  /// Build the shared `WHERE` clause + bound variables for both audit queries.
  /// [payment] is `'all' | 'cash' | 'credit'`; [search] matches invoice id or
  /// customer name (empty = no text filter).
  (String, List<Variable>) _auditWhere({
    required int fromMs,
    required int toMs,
    required String payment,
    required String search,
  }) {
    final where = StringBuffer('WHERE i.created_at BETWEEN ? AND ?');
    final vars = <Variable>[Variable.withInt(fromMs), Variable.withInt(toMs)];
    if (payment == 'credit') {
      where.write(' AND le.invoice_id IS NOT NULL');
    } else if (payment == 'cash') {
      where.write(' AND le.invoice_id IS NULL');
    }
    if (search.isNotEmpty) {
      where.write(' AND (i.id LIKE ? OR c.name LIKE ?)');
      final like = '%$search%';
      vars..add(Variable.withString(like))..add(Variable.withString(like));
    }
    return (where.toString(), vars);
  }

  /// Reactive, paginated audit list. [orderBySql] MUST be a caller-whitelisted
  /// fragment (never user input) — the repository maps [SalesSort] to it.
  Stream<List<AuditInvoiceRow>> watchAuditInvoices({
    required int fromMs,
    required int toMs,
    required String payment,
    required String search,
    required String orderBySql,
    required int limit,
    required int offset,
  }) {
    final (whereSql, vars) = _auditWhere(
        fromMs: fromMs, toMs: toMs, payment: payment, search: search);
    final sql = '''
SELECT i.id AS id, i.created_at AS created_at, i.total_amount AS total_amount,
       c.name AS customer_name,
       (le.invoice_id IS NOT NULL) AS is_credit,
       (SELECT COUNT(*) FROM sales_items si WHERE si.invoice_id = i.id) AS item_count
FROM sales_invoices i
LEFT JOIN ledger_entries le ON le.invoice_id = i.id AND le.entry_type = 'charge'
LEFT JOIN customers c ON c.id = le.customer_id
$whereSql
ORDER BY $orderBySql
LIMIT ? OFFSET ?''';
    final allVars = [...vars, Variable.withInt(limit), Variable.withInt(offset)];
    return customSelect(
      sql,
      variables: allVars,
      readsFrom: {salesInvoices, salesItems, ledgerEntries, customers},
    ).watch().map((rows) => rows
        .map((r) => AuditInvoiceRow(
              id: r.read<String>('id'),
              createdAt: r.read<int>('created_at'),
              totalAmount: r.read<double>('total_amount'),
              customerName: r.readNullable<String>('customer_name'),
              isCredit: r.read<int>('is_credit') != 0,
              itemCount: r.read<int>('item_count'),
            ))
        .toList());
  }

  /// Reactive summary aggregate over the same filter (no pagination). Cash total
  /// is derived in Dart as `total - creditTotal`.
  Stream<AuditSummaryRow> watchAuditSummary({
    required int fromMs,
    required int toMs,
    required String payment,
    required String search,
  }) {
    final (whereSql, vars) = _auditWhere(
        fromMs: fromMs, toMs: toMs, payment: payment, search: search);
    // Estimated profit is summed per invoice via a *correlated subquery* over
    // its items (so the item rows don't fan out the invoice-level SUMs): per
    // line, (price − cost) × qty − line discount; then minus the invoice-level
    // discount. All snapshotted at sale time, so it's historical-accurate.
    final sql = '''
SELECT COUNT(*) AS cnt,
       COALESCE(SUM(i.total_amount), 0.0) AS total,
       COALESCE(SUM(CASE WHEN le.invoice_id IS NOT NULL THEN i.total_amount ELSE 0 END), 0.0) AS credit_total,
       COALESCE(SUM(
         (SELECT COALESCE(SUM((si.price - si.cost) * si.quantity - si.discount), 0.0)
          FROM sales_items si WHERE si.invoice_id = i.id)
         - i.invoice_discount
       ), 0.0) AS profit
FROM sales_invoices i
LEFT JOIN ledger_entries le ON le.invoice_id = i.id AND le.entry_type = 'charge'
LEFT JOIN customers c ON c.id = le.customer_id
$whereSql''';
    return customSelect(
      sql,
      variables: vars,
      readsFrom: {salesInvoices, salesItems, ledgerEntries, customers},
    ).map((r) => AuditSummaryRow(
          count: r.read<int>('cnt'),
          total: r.read<double>('total'),
          creditTotal: r.read<double>('credit_total'),
          profit: r.read<double>('profit'),
        )).watchSingle();
  }

  /// Record a sale atomically: insert the invoice, insert its line items, and
  /// deduct each sold quantity from product on-hand stock — all in one
  /// transaction. Stock is decremented *relatively* (`quantity = quantity - ?`)
  /// straight in SQL, so it never overwrites the rest of the product row and
  /// can't clobber a concurrent edit to price/name/cost.
  ///
  /// The deduction is clamped at 0 (`MAX(quantity - ?, 0)`) so on-hand can never
  /// go negative: overselling a tracked item, or selling one that is untracked
  /// (quantity 0) or was deleted mid-cart (matches 0 rows), leaves on-hand at 0
  /// instead of a nonsensical negative. The sale itself always completes and is
  /// recorded in full via the snapshotted line item (name/price/cost) — a POS
  /// must never block a sale the cashier is physically making.
  ///
  /// For a **credit sale**, pass [creditCharge] — the customer's ledger `charge`
  /// entry (amount = invoice total, linked to this invoice). It is written in
  /// the *same* transaction, so a sale-on-credit can never leave an invoice
  /// without its matching debt (or vice versa).
  ///
  /// For a **cash sale**, pass [cashReceipt] — a positive cashbox entry (amount
  /// = invoice total, linked to this invoice), likewise written in the same
  /// transaction so the cash-on-hand balance can't drift from the sale.
  /// [creditCharge] and [cashReceipt] are mutually exclusive by construction
  /// (cash → cashbox, credit → ledger, never both).
  /// For a **serialized sale** (Plan 012), pass [soldUnitIds] — the physical
  /// units the cart lines consumed. They are marked sold and linked to this
  /// invoice inside the *same* transaction, so a unit can never be marked sold
  /// by an invoice that failed to save, nor an invoice reference a unit that was
  /// never consumed.
  Future<void> insertInvoiceWithItems({
    required SalesInvoicesCompanion invoice,
    required List<SalesItemsCompanion> items,
    LedgerEntriesCompanion? creditCharge,
    CashboxTransactionsCompanion? cashReceipt,
    List<String> soldUnitIds = const [],
  }) =>
      transaction(() async {
        await into(salesInvoices).insert(invoice);
        for (final item in items) {
          await into(salesItems).insert(item);
          // `customUpdate` with `updates:`, never `customStatement`: the raw
          // form writes the row but tells Drift nothing, so `watchAllProducts`
          // never re-runs and every screen keeps showing the pre-sale quantity
          // until the app restarts. The stock was decrementing correctly all
          // along — it simply never reached the UI, which reads as "stock does
          // not go down after a sale".
          //
          // Still raw SQL rather than a typed update because the write is
          // *relative* (`quantity - ?`) and floor-clamped in one statement, so
          // two concurrent sales can't read-modify-write over each other.
          await customUpdate(
            'UPDATE products SET quantity = MAX(quantity - ?, 0) WHERE id = ?',
            variables: [
              Variable<double>(item.quantity.value),
              Variable<String>(item.productId.value),
            ],
            updates: {products},
          );
        }
        if (creditCharge != null) {
          await into(ledgerEntries).insert(creditCharge);
        }
        if (cashReceipt != null) {
          await into(cashboxTransactions).insert(cashReceipt);
        }
        if (soldUnitIds.isNotEmpty) {
          // Serialized units (Plan 012). Note the quantity is NOT re-synced from
          // the unit count here: the loop above already decremented
          // `products.quantity` for every line, serialized or not, so doing both
          // would double-count the same sale.
          final soldAt = invoice.createdAt.value;
          for (final unitId in soldUnitIds) {
            await (update(productUnits)..where((u) => u.id.equals(unitId)))
                .write(ProductUnitsCompanion(
              status: const Value('sold'),
              soldInvoiceId: invoice.id,
              soldAt: Value(soldAt),
            ));
          }
        }
      });

  /// Delete an invoice together with its line items in one transaction, so no
  /// orphaned `sales_items` rows are left behind. Also reverses the invoice's
  /// cashbox entry (if it was a cash sale) so the cash-on-hand balance stays
  /// honest; no-op for a credit sale (nothing was posted there).
  ///
  /// **Incomplete for credit sales — do not wire this to a UI as-is.** A credit
  /// sale also writes a `charge` row to `ledger_entries` (see the ledger
  /// section of CLAUDE.md), and this does not remove it. Deleting a credit
  /// invoice today would leave the customer still owing money for a sale that
  /// no longer exists, and the debt is derived from those rows, so the error is
  /// permanent and invisible. Nothing calls this yet; whoever adds "delete
  /// invoice" must delete the matching `ledger_entries` row (by `invoiceId`) in
  /// this same transaction.
  Future<void> deleteInvoice(String id) => transaction(() async {
        await (delete(salesItems)..where((i) => i.invoiceId.equals(id))).go();
        await (delete(salesInvoices)..where((i) => i.id.equals(id))).go();
        await (delete(cashboxTransactions)
              ..where((c) => c.relatedId.equals(id)))
            .go();
        // Release any serialized units this invoice consumed back to stock
        // (Plan 012) — the same "reverse what the source posted" rule the
        // cashbox line above follows. Their SKUs' cached quantities are then
        // rebuilt from the authoritative unit count.
        final freed = await (select(productUnits)
              ..where((u) => u.soldInvoiceId.equals(id)))
            .get();
        if (freed.isNotEmpty) {
          await (update(productUnits)..where((u) => u.soldInvoiceId.equals(id)))
              .write(const ProductUnitsCompanion(
            status: Value('inStock'),
            soldInvoiceId: Value(''),
            soldAt: Value(0),
          ));
          for (final productId in freed.map((r) => r.productId).toSet()) {
            await customUpdate(
              'UPDATE products SET quantity = ('
              '  SELECT COUNT(*) FROM product_units'
              "  WHERE product_id = ? AND status = 'inStock'"
              ') WHERE id = ? AND is_serialized = 1',
              variables: [
                Variable<String>(productId),
                Variable<String>(productId),
              ],
              updates: {products},
            );
          }
        }
      });
}

/// Projection returned by [SalesDao.watchAuditInvoices]: an invoice with its
/// derived payment type, customer, and item count.
class AuditInvoiceRow {
  final String id;
  final int createdAt; // ms since epoch
  final double totalAmount;
  final String? customerName;
  final bool isCredit;
  final int itemCount;
  const AuditInvoiceRow({
    required this.id,
    required this.createdAt,
    required this.totalAmount,
    required this.customerName,
    required this.isCredit,
    required this.itemCount,
  });
}

/// Projection returned by [SalesDao.watchAuditSummary].
class AuditSummaryRow {
  final int count;
  final double total;
  final double creditTotal;

  /// Estimated profit over the filtered set (revenue − cost − discounts).
  final double profit;
  const AuditSummaryRow({
    required this.count,
    required this.total,
    required this.creditTotal,
    this.profit = 0,
  });
}

