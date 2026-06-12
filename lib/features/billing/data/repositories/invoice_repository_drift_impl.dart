import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/sales_dao.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/repositories/invoice_repository.dart';
class InvoiceRepositoryDriftImpl implements InvoiceRepository {
  final SalesDao _dao;
  const InvoiceRepositoryDriftImpl(this._dao);
  @override
  Future<Either<Failure, void>> saveInvoice(Invoice invoice, List<InvoiceItem> items) async {
    try {
      await _dao.insertInvoiceWithItems(
        invoice: SalesInvoicesCompanion(
          id: Value(invoice.id),
          createdAt: Value(invoice.createdAt.millisecondsSinceEpoch),
          totalAmount: Value(invoice.totalAmount),
          customerId: Value(invoice.customerId),
          customerName: Value(invoice.customerName),
        ),
        items: items.map((i) => SalesItemsCompanion(
          invoiceId: Value(invoice.id),
          productId: Value(i.productId),
          productName: Value(i.productName),
          price: Value(i.price),
          quantity: Value(i.quantity),
        )).toList(),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
  @override
  Future<Either<Failure, List<Invoice>>> getAllInvoices() async {
    try {
      final rows = await _dao.getAllInvoices();
      return Right(rows.map((r) => Invoice(
        id: r.id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
        totalAmount: r.totalAmount,
        customerId: r.customerId,
        customerName: r.customerName,
      )).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
  @override
  Future<Either<Failure, List<InvoiceItem>>> getInvoiceItems(String invoiceId) async {
    try {
      final rows = await _dao.getItemsForInvoice(invoiceId);
      return Right(rows.map((r) => InvoiceItem(
        id: r.id,
        invoiceId: r.invoiceId,
        productId: r.productId,
        productName: r.productName,
        price: r.price,
        quantity: r.quantity,
      )).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
  @override
  Future<Either<Failure, void>> deleteInvoice(String id) async {
    try {
      await _dao.deleteInvoice(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
