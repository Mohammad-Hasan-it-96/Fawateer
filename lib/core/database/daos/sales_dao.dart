import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sales_invoices_table.dart';
import '../tables/sales_items_table.dart';

part 'sales_dao.g.dart';

@DriftAccessor(tables: [SalesInvoices, SalesItems])
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
  Future<void> insertInvoiceWithItems({
    required SalesInvoicesCompanion invoice,
    required List<SalesItemsCompanion> items,
  }) =>
      transaction(() async {
        await into(salesInvoices).insert(invoice);
        for (final item in items) {
          await into(salesItems).insert(item);
          await customStatement(
            'UPDATE products SET quantity = quantity - ? WHERE id = ?',
            [item.quantity.value, item.productId.value],
          );
        }
      });

  /// Delete an invoice together with its line items in one transaction, so no
  /// orphaned `sales_items` rows are left behind.
  Future<void> deleteInvoice(String id) => transaction(() async {
        await (delete(salesItems)..where((i) => i.invoiceId.equals(id))).go();
        await (delete(salesInvoices)..where((i) => i.id.equals(id))).go();
      });
}

