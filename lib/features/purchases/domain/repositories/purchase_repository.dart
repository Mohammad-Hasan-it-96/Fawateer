import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/purchase_invoice.dart';
import '../entities/purchase_item.dart';

abstract class PurchaseRepository {
  Future<Either<Failure, void>> savePurchase(
    PurchaseInvoice invoice,
    List<PurchaseItem> items,
  );
  Future<Either<Failure, List<PurchaseInvoice>>> getAllPurchases();
  Future<Either<Failure, List<PurchaseItem>>> getPurchaseItems(String invoiceId);
  Future<Either<Failure, void>> deletePurchase(String id);
}

