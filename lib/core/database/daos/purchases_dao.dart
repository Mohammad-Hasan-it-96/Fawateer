import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/purchase_invoices_table.dart';
import '../tables/purchase_items_table.dart';

part 'purchases_dao.g.dart';

@DriftAccessor(tables: [PurchaseInvoices, PurchaseItems])
class PurchasesDao extends DatabaseAccessor<AppDatabase>
    with _$PurchasesDaoMixin {
  PurchasesDao(super.db);

  /// All purchase invoices ordered by newest first.
  Future<List<PurchaseInvoiceRow>> getAllInvoices() =>
      (select(purchaseInvoices)
            ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
          .get();

  /// Line items for a specific purchase invoice.
  Future<List<PurchaseItemRow>> getItemsForInvoice(String invoiceId) =>
      (select(purchaseItems)..where((i) => i.invoiceId.equals(invoiceId)))
          .get();

  /// Save a purchase invoice together with its items in one transaction.
  Future<void> insertInvoiceWithItems({
    required PurchaseInvoicesCompanion invoice,
    required List<PurchaseItemsCompanion> items,
  }) =>
      transaction(() async {
        await into(purchaseInvoices).insert(invoice);
        for (final item in items) {
          await into(purchaseItems).insert(item);
        }
      });

  /// Delete a purchase invoice by [id].
  Future<int> deleteInvoice(String id) =>
      (delete(purchaseInvoices)..where((i) => i.id.equals(id))).go();
}

