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

  /// Save an invoice together with its line items in a single transaction.
  Future<void> insertInvoiceWithItems({
    required SalesInvoicesCompanion invoice,
    required List<SalesItemsCompanion> items,
  }) =>
      transaction(() async {
        await into(salesInvoices).insert(invoice);
        for (final item in items) {
          await into(salesItems).insert(item);
        }
      });

  /// Delete an invoice (line items must be handled separately or via a trigger).
  Future<int> deleteInvoice(String id) =>
      (delete(salesInvoices)..where((i) => i.id.equals(id))).go();
}

