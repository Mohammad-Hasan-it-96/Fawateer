import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/invoice.dart';
import '../entities/invoice_item.dart';

abstract class InvoiceRepository {
  /// Persist a sale. Pass [customerId] for a **sale on credit**: a matching
  /// `charge` ledger entry (amount = invoice total) is written in the same
  /// transaction as the invoice. Null = a normal cash sale.
  Future<Either<Failure, void>> saveInvoice(
    Invoice invoice,
    List<InvoiceItem> items, {
    String? customerId,
  });
  Future<Either<Failure, List<Invoice>>> getAllInvoices();

  /// Reactive stream of all invoices (newest first), updated on every write.
  Stream<List<Invoice>> watchInvoices();

  Future<Either<Failure, List<InvoiceItem>>> getInvoiceItems(String invoiceId);
  Future<Either<Failure, void>> deleteInvoice(String id);
}

