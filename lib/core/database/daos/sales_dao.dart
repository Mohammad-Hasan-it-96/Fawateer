import 'package:drift/drift.dart';
import '../../sync/sync_clock.dart';
import '../app_database.dart';
import '../tables/sales_invoices_table.dart';
import '../tables/sales_items_table.dart';
import '../tables/ledger_entries_table.dart';
import '../tables/cashbox_transactions_table.dart';
import '../tables/customers_table.dart';
import '../tables/products_table.dart';
import '../tables/product_units_table.dart';
import '../tables/stock_movements_table.dart';

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
  // A sale appends one signed movement per line (Plan 002, Phase 0).
  StockMovements,
])
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(super.db);

  /// All invoices ordered by newest first.
  Future<List<SalesInvoiceRow>> getAllInvoices() => (select(salesInvoices)
        ..where((i) => i.deletedAt.equals(''))
        ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
      .get();

  /// Reactive stream of all invoices.
  Stream<List<SalesInvoiceRow>> watchAllInvoices() => (select(salesInvoices)
        ..where((i) => i.deletedAt.equals(''))
        ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
      .watch();

  /// All line items belonging to a specific invoice.
  Future<List<SalesItemRow>> getItemsForInvoice(String invoiceId) =>
      (select(salesItems)
            ..where(
                (i) => i.invoiceId.equals(invoiceId) & i.deletedAt.equals('')))
          .get();

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
    final where =
        StringBuffer("WHERE i.deleted_at = '' AND i.created_at BETWEEN ? AND ?");
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
       (SELECT COUNT(*) FROM sales_items si
         WHERE si.invoice_id = i.id AND si.deleted_at = '') AS item_count
FROM sales_invoices i
LEFT JOIN ledger_entries le ON le.invoice_id = i.id AND le.entry_type = 'charge'
                           AND le.deleted_at = ''
LEFT JOIN customers c ON c.id = le.customer_id AND c.deleted_at = ''
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
          FROM sales_items si
          WHERE si.invoice_id = i.id AND si.deleted_at = '')
         - i.invoice_discount
       ), 0.0) AS profit
FROM sales_invoices i
LEFT JOIN ledger_entries le ON le.invoice_id = i.id AND le.entry_type = 'charge'
                           AND le.deleted_at = ''
LEFT JOIN customers c ON c.id = le.customer_id AND c.deleted_at = ''
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
  /// append one signed stock movement per line — all in one transaction.
  ///
  /// Stock is recorded as an **event, not a new total** (Plan 002, Phase 0).
  /// The old code decremented `products.quantity` in place; under sync that
  /// scalar is merged last-write-wins, so two devices each selling one of five
  /// converge on "4" and one sale disappears from the books entirely. A
  /// movement of `-quantity` cannot be overwritten — devices merge the log by
  /// union and both sales count.
  ///
  /// The sale itself always completes and is recorded in full via the
  /// snapshotted line item (name/price/cost) — a POS must never block a sale
  /// the cashier is physically making. Selling an untracked item, or one
  /// deleted mid-cart, simply drives the derived sum negative; the cached
  /// `products.quantity` still floors at 0 for display (see
  /// `kRecomputeQuantitySql`), so nothing on screen changes.
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
    required SyncStamp stamp,
    LedgerEntriesCompanion? creditCharge,
    CashboxTransactionsCompanion? cashReceipt,
    List<String> soldUnitIds = const [],
  }) =>
      transaction(() async {
        await into(salesInvoices).insert(invoice);
        final soldAt = invoice.createdAt.value;
        final touched = <String>{};
        for (final item in items) {
          await into(salesItems).insert(item);
          touched.add(item.productId.value);
          // The movement id is derived from the line's own sync id rather than
          // freshly generated, so a sale that arrives twice inserts the same
          // row instead of deducting the stock a second time.
          await into(stockMovements).insert(StockMovementsCompanion.insert(
            id: 'stock-${item.uuid.value}',
            productId: item.productId.value,
            delta: -item.quantity.value,
            reason: const Value('sale'),
            relatedId: invoice.id,
            occurredAt: soldAt,
            createdAt: soldAt,
            updatedAt: Value(stamp.hlc),
            originDevice: Value(stamp.device),
          ));
        }
        if (creditCharge != null) {
          await into(ledgerEntries).insert(creditCharge);
        }
        if (cashReceipt != null) {
          await into(cashboxTransactions).insert(cashReceipt);
        }
        if (soldUnitIds.isNotEmpty) {
          // Serialized units (Plan 012).
          for (final unitId in soldUnitIds) {
            await (update(productUnits)..where((u) => u.id.equals(unitId)))
                .write(ProductUnitsCompanion(
              status: const Value('sold'),
              soldInvoiceId: invoice.id,
              soldAt: Value(soldAt),
              updatedAt: Value(stamp.hlc),
              originDevice: Value(stamp.device),
            ));
          }
        }
        // Refresh the cached on-hand LAST, once per product. It has to come
        // after the units are marked sold: for a serialized SKU the cache is
        // rebuilt from the live unit count, so recomputing mid-loop would read
        // the pre-sale count and put the stock straight back.
        //
        // `customUpdate` with `updates:`, never `customStatement`: the raw form
        // writes the row but tells Drift nothing, so `watchAllProducts` never
        // re-runs and every screen keeps showing the pre-sale quantity until
        // the app restarts. The stock was decrementing correctly all along — it
        // simply never reached the UI, which reads as "stock does not go down
        // after a sale".
        for (final productId in touched) {
          await customUpdate(
            kRecomputeQuantitySql,
            variables: [Variable<String>(productId)],
            updates: {products},
          );
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
  /// (cash entry and/or ledger charge) is retired, then exactly one row is
  /// written for the payment type now being asked for. That makes every
  /// direction — cash→credit, credit→cash, customer A→B — the same code path,
  /// and re-applying the same choice a no-op instead of a double posting.
  ///
  /// **Retired means tombstoned, not deleted** (the sync rule): a physically
  /// removed row is "absent here, present there" to a merge, and comes back
  /// from the other till on the next pull — so a corrected sale would silently
  /// regain the cash entry it was supposed to lose, and the customer would be
  /// charged twice.
  ///
  /// Both new rows are dated at the **sale's** time, not now. This is a
  /// correction of a mis-recorded sale, not a payment happening today: dating
  /// it today would leave yesterday's cash report wrong *and* make today's
  /// wrong too. A customer actually paying off a debt is a different thing —
  /// that is a ledger `payment` entry, which this must never be used for.
  ///
  /// Known limit, shared with [softDeleteInvoice]: ledger `payment` rows carry
  /// no invoice link, so a repayment the customer already made against this
  /// debt cannot be identified and is left in place. Turning such a sale into
  /// cash leaves that payment standing as a credit on their account, which is
  /// visible on the statement rather than silent.
  Future<PaymentChangeResult> setInvoicePayment({
    required String invoiceId,
    required String? customerId,
    required String newRowId,
    required SyncStamp stamp,
  }) =>
      transaction(() async {
        final invoice = await (select(salesInvoices)
              ..where((i) => i.id.equals(invoiceId) & i.deletedAt.equals('')))
            .getSingleOrNull();
        if (invoice == null) return PaymentChangeResult.invoiceMissing;
        // No FK constraints are declared on these tables yet, so an unknown id
        // would insert happily and leave a charge nobody owns — the audit
        // query's LEFT JOIN would just render it as a credit sale with no name.
        // Checking here is cheap and keeps that impossible.
        if (customerId != null) {
          final customer = await (select(customers)
                ..where((c) => c.id.equals(customerId) & c.deletedAt.equals('')))
              .getSingleOrNull();
          if (customer == null) return PaymentChangeResult.customerMissing;
        }

        final amount = (invoice.totalAmount * 100).roundToDouble() / 100;
        await (update(cashboxTransactions)
              ..where((c) =>
                  c.relatedId.equals(invoiceId) & c.deletedAt.equals('')))
            .write(CashboxTransactionsCompanion(
          deletedAt: Value(stamp.hlc),
          updatedAt: Value(stamp.hlc),
          originDevice: Value(stamp.device),
        ));
        await (update(ledgerEntries)
              ..where((e) =>
                  e.invoiceId.equals(invoiceId) & e.deletedAt.equals('')))
            .write(LedgerEntriesCompanion(
          deletedAt: Value(stamp.hlc),
          updatedAt: Value(stamp.hlc),
          originDevice: Value(stamp.device),
        ));

        if (customerId == null) {
          await into(cashboxTransactions).insert(CashboxTransactionsCompanion(
            id: Value(newRowId),
            type: const Value('cashSale'),
            amount: Value(amount),
            relatedId: Value(invoiceId),
            occurredAt: Value(invoice.createdAt),
            createdAt: Value(invoice.createdAt),
            updatedAt: Value(stamp.hlc),
            originDevice: Value(stamp.device),
          ));
        } else {
          await into(ledgerEntries).insert(LedgerEntriesCompanion(
            id: Value(newRowId),
            customerId: Value(customerId),
            invoiceId: Value(invoiceId),
            entryType: const Value('charge'),
            amount: Value(amount),
            createdAt: Value(invoice.createdAt),
            updatedAt: Value(stamp.hlc),
            originDevice: Value(stamp.device),
          ));
        }
        return PaymentChangeResult.ok;
      });

  /// Tombstone an invoice together with its line items in one transaction, so
  /// no line is left visible without its invoice. Also retires the money the
  /// sale posted — the cashbox entry of a cash sale, or the ledger `charge` of
  /// a credit one — and the stock movements it wrote.
  ///
  /// The lines are tombstoned individually rather than left to fall out with
  /// their parent: the sync contract replicates rows, not row trees, so a line
  /// whose only claim to being deleted is its invoice's tombstone would arrive
  /// on the other device as a live orphan.
  ///
  /// **The ledger charge is the part that was missing** (Plan 016 A). Without
  /// it, deleting a credit invoice left the customer owing money for a sale
  /// that no longer existed — and because the balance is *derived* from those
  /// rows, the error was permanent and invisible. This method carried a "do not
  /// wire this to a UI as-is" warning for exactly that reason until the delete
  /// button was built on the release branch; the warning was right, and it was
  /// understated.
  Future<void> softDeleteInvoice(String id, SyncStamp stamp) =>
      transaction(() async {
        await (update(salesItems)
              ..where(
                  (i) => i.invoiceId.equals(id) & i.deletedAt.equals('')))
            .write(SalesItemsCompanion(
          deletedAt: Value(stamp.hlc),
          updatedAt: Value(stamp.hlc),
          originDevice: Value(stamp.device),
        ));
        await (update(salesInvoices)
              ..where((i) => i.id.equals(id) & i.deletedAt.equals('')))
            .write(SalesInvoicesCompanion(
          deletedAt: Value(stamp.hlc),
          updatedAt: Value(stamp.hlc),
          originDevice: Value(stamp.device),
        ));
        await (update(cashboxTransactions)
              ..where(
                  (c) => c.relatedId.equals(id) & c.deletedAt.equals('')))
            .write(CashboxTransactionsCompanion(
          deletedAt: Value(stamp.hlc),
          updatedAt: Value(stamp.hlc),
          originDevice: Value(stamp.device),
        ));
        // Take back the stock the sale removed, by tombstoning the movements
        // it posted — the same "reverse what the source posted" rule the
        // cashbox line above follows, done the same way. Tombstoned rather
        // than compensated with an opposite movement because the sale did not
        // happen: the honest record is that the event is gone. A genuine
        // *return* is a different event and gets its own reason.
        final touched = <String>{};
        final reversed = await (select(stockMovements)
              ..where((m) => m.relatedId.equals(id) & m.deletedAt.equals('')))
            .get();
        if (reversed.isNotEmpty) {
          await (update(stockMovements)
                ..where(
                    (m) => m.relatedId.equals(id) & m.deletedAt.equals('')))
              .write(StockMovementsCompanion(
            deletedAt: Value(stamp.hlc),
            updatedAt: Value(stamp.hlc),
            originDevice: Value(stamp.device),
          ));
          touched.addAll(reversed.map((m) => m.productId));
        }

        // Retire the debt a credit sale created. `ledger_entries.invoiceId` is
        // set only by that path (null for manual charges and payments), so this
        // takes exactly the one `charge` this invoice posted.
        //
        // Tombstoned, never deleted: a physically removed row reads as "absent
        // here, present there" to a merge and is resurrected from the other
        // till on the next pull — so the customer would silently start owing
        // the money again, for a sale that no longer exists.
        await (update(ledgerEntries)
              ..where((e) => e.invoiceId.equals(id) & e.deletedAt.equals('')))
            .write(LedgerEntriesCompanion(
          deletedAt: Value(stamp.hlc),
          updatedAt: Value(stamp.hlc),
          originDevice: Value(stamp.device),
        ));

        // Release any serialized units this invoice consumed back to stock
        // (Plan 012). The units themselves are NOT tombstoned: the handsets
        // still exist and are back on the shelf; only the sale was undone.
        final freed = await (select(productUnits)
              ..where((u) =>
                  u.soldInvoiceId.equals(id) & u.deletedAt.equals('')))
            .get();
        if (freed.isNotEmpty) {
          await (update(productUnits)
                ..where((u) =>
                    u.soldInvoiceId.equals(id) & u.deletedAt.equals('')))
              .write(ProductUnitsCompanion(
            status: const Value('inStock'),
            soldInvoiceId: const Value(''),
            soldAt: const Value(0),
            updatedAt: Value(stamp.hlc),
            originDevice: Value(stamp.device),
          ));
          touched.addAll(freed.map((r) => r.productId));
        }

        for (final productId in touched) {
          await customUpdate(
            kRecomputeQuantitySql,
            variables: [Variable<String>(productId)],
            updates: {products},
          );
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

