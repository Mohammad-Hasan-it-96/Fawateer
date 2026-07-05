import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sales_invoices_table.dart';
import '../tables/sales_items_table.dart';
import '../tables/ledger_entries_table.dart';

part 'sales_dao.g.dart';

@DriftAccessor(tables: [SalesInvoices, SalesItems, LedgerEntries])
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
  Future<void> insertInvoiceWithItems({
    required SalesInvoicesCompanion invoice,
    required List<SalesItemsCompanion> items,
    LedgerEntriesCompanion? creditCharge,
  }) =>
      transaction(() async {
        await into(salesInvoices).insert(invoice);
        for (final item in items) {
          await into(salesItems).insert(item);
          await customStatement(
            'UPDATE products SET quantity = MAX(quantity - ?, 0) WHERE id = ?',
            [item.quantity.value, item.productId.value],
          );
        }
        if (creditCharge != null) {
          await into(ledgerEntries).insert(creditCharge);
        }
      });

  /// Delete an invoice together with its line items in one transaction, so no
  /// orphaned `sales_items` rows are left behind.
  Future<void> deleteInvoice(String id) => transaction(() async {
        await (delete(salesItems)..where((i) => i.invoiceId.equals(id))).go();
        await (delete(salesInvoices)..where((i) => i.id.equals(id))).go();
      });
}

