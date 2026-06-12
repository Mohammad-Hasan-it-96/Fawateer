import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/invoice.dart';
import '../entities/invoice_item.dart';

abstract class InvoiceRepository {
  Future<Either<Failure, void>> saveInvoice(
    Invoice invoice,
    List<InvoiceItem> items,
  );
  Future<Either<Failure, List<Invoice>>> getAllInvoices();
  Future<Either<Failure, List<InvoiceItem>>> getInvoiceItems(String invoiceId);
  Future<Either<Failure, void>> deleteInvoice(String id);
}

