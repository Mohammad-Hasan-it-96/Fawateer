import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/invoice.dart';
import '../entities/invoice_item.dart';
import '../entities/invoice_list_item.dart';
import '../entities/sales_filter.dart';
import '../entities/sales_summary.dart';

abstract class InvoiceRepository {
  /// Persist a sale. Pass [customerId] for a **sale on credit**: a matching
  /// `charge` ledger entry (amount = invoice total) is written in the same
  /// transaction as the invoice. Null = a normal cash sale.
  Future<Either<Failure, void>> saveInvoice(
    Invoice invoice,
    List<InvoiceItem> items, {
    String? customerId,

    /// Serialized units (Plan 012) consumed by this sale. Marked sold and linked
    /// to the invoice inside the same transaction, so a unit can never be marked
    /// sold by an invoice that failed to save.
    List<String> soldUnitIds,
  });
  Future<Either<Failure, List<Invoice>>> getAllInvoices();

  /// Reactive stream of all invoices (newest first), updated on every write.
  Stream<List<Invoice>> watchInvoices();

  /// Reactive, paginated audit list matching [filter] — carries each invoice's
  /// derived payment type, customer, and item count. Re-emits after every sale.
  /// [limit] bounds how many rows the window returns; grow it to page in more.
  Stream<List<InvoiceListItem>> watchFilteredInvoices(
    SalesFilter filter, {
    int limit,
    int offset,
  });

  /// Reactive summary aggregate (count/total/cash/credit) over the same
  /// [filter] as [watchFilteredInvoices].
  Stream<SalesSummary> watchSummary(SalesFilter filter);

  Future<Either<Failure, List<InvoiceItem>>> getInvoiceItems(String invoiceId);
  Future<Either<Failure, void>> deleteInvoice(String id);

  /// Correct how an existing sale was paid (Plan 016 C-a): pass [customerId]
  /// to book it as credit for that customer, or null to book it as cash.
  ///
  /// Only the money record moves — the invoice, its lines, the total and the
  /// stock are untouched, so the receipt still reprints exactly as printed.
  /// Fails with [NotFoundFailure] if the invoice or the customer is gone.
  Future<Either<Failure, void>> changeInvoicePayment(
    String invoiceId, {
    required String? customerId,
  });
}

