import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/invoice.dart';
import '../entities/invoice_item.dart';
import '../repositories/invoice_repository.dart';

class GetAllInvoicesUseCase implements UseCase<List<Invoice>, NoParams> {
  final InvoiceRepository repository;
  GetAllInvoicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Invoice>>> call(NoParams params) =>
      repository.getAllInvoices();
}

class GetInvoiceItemsUseCase implements UseCase<List<InvoiceItem>, String> {
  final InvoiceRepository repository;
  GetInvoiceItemsUseCase(this.repository);

  @override
  Future<Either<Failure, List<InvoiceItem>>> call(String invoiceId) =>
      repository.getInvoiceItems(invoiceId);
}
