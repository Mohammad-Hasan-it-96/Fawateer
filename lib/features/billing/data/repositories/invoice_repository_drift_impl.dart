import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/sales_dao.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/repositories/invoice_repository.dart';

class InvoiceRepositoryDriftImpl implements InvoiceRepository {
  final SalesDao _dao;
  const InvoiceRepositoryDriftImpl(this._dao);

  static Invoice _toEntity(SalesInvoiceRow r) => Invoice(
        id: r.id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
        totalAmount: r.totalAmount,
      );

  @override
  Future<Either<Failure, void>> saveInvoice(
      Invoice invoice, List<InvoiceItem> items,
      {String? customerId}) async {
    try {
      // On a credit sale, the customer's debt is booked atomically with the
      // invoice (amount = total, linked back via invoiceId).
      final creditCharge = customerId == null
          ? null
          : LedgerEntriesCompanion(
              id: Value(const Uuid().v4()),
              customerId: Value(customerId),
              invoiceId: Value(invoice.id),
              entryType: const Value('charge'),
              amount:
                  Value((invoice.totalAmount * 100).roundToDouble() / 100),
              createdAt: Value(invoice.createdAt.millisecondsSinceEpoch),
            );
      await _dao.insertInvoiceWithItems(
        invoice: SalesInvoicesCompanion(
          id: Value(invoice.id),
          createdAt: Value(invoice.createdAt.millisecondsSinceEpoch),
          totalAmount: Value(invoice.totalAmount),
        ),
        items: items
            .map((i) => SalesItemsCompanion(
                  invoiceId: Value(invoice.id),
                  productId: Value(i.productId),
                  productName: Value(i.productName),
                  price: Value(i.price),
                  cost: Value(i.cost),
                  quantity: Value(i.quantity),
                ))
            .toList(),
        creditCharge: creditCharge,
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
      return Right(rows.map(_toEntity).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Stream<List<Invoice>> watchInvoices() =>
      _dao.watchAllInvoices().map((rows) => rows.map(_toEntity).toList());

  @override
  Future<Either<Failure, List<InvoiceItem>>> getInvoiceItems(
      String invoiceId) async {
    try {
      final rows = await _dao.getItemsForInvoice(invoiceId);
      return Right(rows
          .map((r) => InvoiceItem(
                id: r.id,
                invoiceId: r.invoiceId,
                productId: r.productId,
                productName: r.productName,
                price: r.price,
                cost: r.cost,
                quantity: r.quantity,
              ))
          .toList());
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
