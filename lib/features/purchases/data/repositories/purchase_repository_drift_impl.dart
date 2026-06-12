import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/purchases_dao.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/purchase_invoice.dart';
import '../../domain/entities/purchase_item.dart';
import '../../domain/repositories/purchase_repository.dart';
class PurchaseRepositoryDriftImpl implements PurchaseRepository {
  final PurchasesDao _dao;
  const PurchaseRepositoryDriftImpl(this._dao);
  @override
  Future<Either<Failure, void>> savePurchase(PurchaseInvoice invoice, List<PurchaseItem> items) async {
    try {
      await _dao.insertInvoiceWithItems(
        invoice: PurchaseInvoicesCompanion(
          id: Value(invoice.id),
          createdAt: Value(invoice.createdAt.millisecondsSinceEpoch),
          totalAmount: Value(invoice.totalAmount),
          supplier: Value(invoice.supplier),
        ),
        items: items.map((i) => PurchaseItemsCompanion(
          invoiceId: Value(invoice.id), productId: Value(i.productId),
          productName: Value(i.productName), cost: Value(i.cost), quantity: Value(i.quantity),
        )).toList(),
      );
      return const Right(null);
    } catch (e) { return Left(CacheFailure(e.toString())); }
  }
  @override
  Future<Either<Failure, List<PurchaseInvoice>>> getAllPurchases() async {
    try {
      final rows = await _dao.getAllInvoices();
      return Right(rows.map((r) => PurchaseInvoice(
        id: r.id, createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
        totalAmount: r.totalAmount, supplier: r.supplier,
      )).toList());
    } catch (e) { return Left(CacheFailure(e.toString())); }
  }
  @override
  Future<Either<Failure, List<PurchaseItem>>> getPurchaseItems(String invoiceId) async {
    try {
      final rows = await _dao.getItemsForInvoice(invoiceId);
      return Right(rows.map((r) => PurchaseItem(
        id: r.id, invoiceId: r.invoiceId, productId: r.productId,
        productName: r.productName, cost: r.cost, quantity: r.quantity,
      )).toList());
    } catch (e) { return Left(CacheFailure(e.toString())); }
  }
  @override
  Future<Either<Failure, void>> deletePurchase(String id) async {
    try { await _dao.deleteInvoice(id); return const Right(null); }
    catch (e) { return Left(CacheFailure(e.toString())); }
  }
}
