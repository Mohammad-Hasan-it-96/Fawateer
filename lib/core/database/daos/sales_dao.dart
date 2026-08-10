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
       c.name AS customer_name, le.customer_id AS customer_id,
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
              customerId: r.readNullable<String>('customer_id'),
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

  /// Correct how an already-recorded sale was paid (Plan 016 C-a): cash ⇄
  /// credit, or move a credit sale to a different customer. Pass [customerId]
  /// for credit, null for cash.
  ///
  /// **The sale itself is not edited, and that is the whole point.** No
  /// snapshot column is touched: the line items, the total, the discounts, the
  /// stock and the serialized units all stay exactly as they were, so the
  /// receipt still reprints byte-for-byte and the invoice number the customer
  /// is holding survives. Only the *money record* moves — which is the thing
  /// that was actually wrong.
  ///
  /// It works by re-deriving rather than diffing: whatever the sale posted
  /// (cash entry and/or ledger charge) is cleared, then exactly one row is
  /// written for the payment type now being asked for. That makes every
  /// direction — cash→credit, credit→cash, customer A→B — the same code path,
  /// and re-applying the same choice a no-op instead of a double posting.
  ///
  /// Both new rows are dated at the **sale's** time, not now. This is a
  /// correction of a mis-recorded sale, not a payment happening today: dating
  /// it today would leave yesterday's cash report wrong *and* make today's
  /// wrong too. A customer actually paying off a debt is a different thing —
  /// that is a ledger `payment` entry, which this must never be used for.
  ///
  /// Known limit, shared with [deleteInvoice]: ledger `payment` rows carry no
  /// invoice link, so a repayment the customer already made against this debt
  /// cannot be identified and is left in place. Turning such a sale into cash
  /// leaves that payment standing as a credit on their account, which is
  /// visible on the statement rather than silent.
  Future<PaymentChangeResult> setInvoicePayment({
    required String invoiceId,
    required String? customerId,
    required String newRowId,
  }) =>
      transaction(() async {
        final invoice = await (select(salesInvoices)
              ..where((i) => i.id.equals(invoiceId)))
            .getSingleOrNull();
        if (invoice == null) return PaymentChangeResult.invoiceMissing;
        // No FK constraints are declared on these tables yet, so an unknown id
        // would insert happily and leave a charge nobody owns — the audit
        // query's LEFT JOIN would just render it as a credit sale with no name.
        // Checking here is cheap and keeps that impossible.
        if (customerId != null) {
          final customer = await (select(customers)
                ..where((c) => c.id.equals(customerId)))
              .getSingleOrNull();
          if (customer == null) return PaymentChangeResult.customerMissing;
        }

        final amount = (invoice.totalAmount * 100).roundToDouble() / 100;
        await (delete(cashboxTransactions)
              ..where((c) => c.relatedId.equals(invoiceId)))
            .go();
        await (delete(ledgerEntries)
              ..where((e) => e.invoiceId.equals(invoiceId)))
            .go();

        if (customerId == null) {
          await into(cashboxTransactions).insert(CashboxTransactionsCompanion(
            id: Value(newRowId),
            type: const Value('cashSale'),
            amount: Value(amount),
            relatedId: Value(invoiceId),
            occurredAt: Value(invoice.createdAt),
            createdAt: Value(invoice.createdAt),
          ));
        } else {
          await into(ledgerEntries).insert(LedgerEntriesCompanion(
            id: Value(newRowId),
            customerId: Value(customerId),
            invoiceId: Value(invoiceId),
            entryType: const Value('charge'),
            amount: Value(amount),
            createdAt: Value(invoice.createdAt),
          ));
        }
        return PaymentChangeResult.ok;
      });

  /// Undo a sale completely, in one transaction (Plan 016 A).
  ///
  /// A sale is never only a piece of paper: it moved stock, and it put money
  /// either in the drawer or on a customer's account. Deleting it has to undo
  /// **all** of that or the books quietly stop adding up, so this reverses, in
  /// order:
  ///
  /// 1. **stock** — the line quantities go back on the shelf (ordinary
  ///    products here; serialized SKUs are rebuilt from their unit count in
  ///    step 5);
  /// 2. the **line items** and the **invoice** itself, so nothing is orphaned;
  /// 3. the **cashbox** inflow a cash sale posted;
  /// 4. the **ledger charge** a credit sale posted — without this the customer
  ///    kept owing money for a sale that no longer existed, and since the
  ///    balance is derived from those rows the error was permanent and
  ///    invisible. This method carried a "do not wire to a UI as-is" warning
  ///    for exactly that reason until the delete button was built;
  /// 5. **serialized units**, released back to stock.
  Future<void> deleteInvoice(String id) => transaction(() async {
        // Put the goods back on the shelf, before the lines are gone.
        //
        // The sale deducted stock; deleting it has to undo that, or a shop's
        // counts drift down by one basket every time a mis-rung sale is
        // removed. Serialized SKUs are excluded here on purpose — their
        // quantity is rebuilt from the authoritative unit count further down,
        // and adding here as well would double it.
        //
        // Known asymmetry: the deduction floors at zero (overselling is
        // allowed), so a line that sold 5 with 1 on hand only took 1 — and this
        // gives back 5. That over-credits in the rare oversell case; not
        // restoring at all would under-credit in *every* case, which is the
        // worse trade.
        final lines =
            await (select(salesItems)..where((i) => i.invoiceId.equals(id)))
                .get();
        for (final line in lines) {
          await customUpdate(
            'UPDATE products SET quantity = quantity + ? '
            'WHERE id = ? AND is_serialized = 0',
            variables: [
              Variable<double>(line.quantity),
              Variable<String>(line.productId),
            ],
            updates: {products},
          );
        }
        await (delete(salesItems)..where((i) => i.invoiceId.equals(id))).go();
        await (delete(salesInvoices)..where((i) => i.id.equals(id))).go();
        await (delete(cashboxTransactions)
              ..where((c) => c.relatedId.equals(id)))
            .go();
        // Reverse the debt a credit sale created. `ledger_entries.invoiceId` is
        // set only by that path (null for manual charges and payments), so this
        // removes exactly the one `charge` this invoice posted.
        //
        // Without it, deleting a credit invoice left the customer owing money
        // for a sale that no longer exists — a balance the shop could not
        // explain and could only fix by hand.
        await (delete(ledgerEntries)..where((e) => e.invoiceId.equals(id))).go();
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

/// Outcome of [SalesDao.setInvoicePayment]. Returned rather than thrown so the
/// repository can map each case to its own [Failure] and the UI can say which
/// record is missing, instead of one opaque "save failed".
enum PaymentChangeResult { ok, invoiceMissing, customerMissing }

/// Projection returned by [SalesDao.watchAuditInvoices]: an invoice with its
/// derived payment type, customer, and item count.
class AuditInvoiceRow {
  final String id;
  final int createdAt; // ms since epoch
  final double totalAmount;
  final String? customerName;

  /// The credit customer's id — what a payment correction needs to pre-select
  /// them (the name alone can't identify a row). Null for a cash sale.
  final String? customerId;
  final bool isCredit;
  final int itemCount;
  const AuditInvoiceRow({
    required this.id,
    required this.createdAt,
    required this.totalAmount,
    required this.customerName,
    this.customerId,
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

