import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/sales_dao.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/entities/invoice_list_item.dart';
import '../../domain/entities/sales_filter.dart';
import '../../domain/entities/sales_summary.dart';
import '../../domain/repositories/invoice_repository.dart';

class InvoiceRepositoryDriftImpl implements InvoiceRepository {
  final SalesDao _dao;
  const InvoiceRepositoryDriftImpl(this._dao);

  static Invoice _toEntity(SalesInvoiceRow r) => Invoice(
        id: r.id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
        totalAmount: r.totalAmount,
      );

  /// Whitelisted `ORDER BY` fragment per sort — never interpolate user input.
  /// A stable secondary key keeps pagination deterministic across equal values.
  static String _orderBySql(SalesSort sort) {
    switch (sort) {
      case SalesSort.newest:
        return 'i.created_at DESC, i.id DESC';
      case SalesSort.oldest:
        return 'i.created_at ASC, i.id ASC';
      case SalesSort.highest:
        return 'i.total_amount DESC, i.created_at DESC';
      case SalesSort.lowest:
        return 'i.total_amount ASC, i.created_at DESC';
    }
  }

  static String _paymentSql(PaymentFilter p) {
    switch (p) {
      case PaymentFilter.all:
        return 'all';
      case PaymentFilter.cash:
        return 'cash';
      case PaymentFilter.credit:
        return 'credit';
    }
  }

  @override
  Future<Either<Failure, void>> saveInvoice(
      Invoice invoice, List<InvoiceItem> items,
      {String? customerId}) async {
    try {
      final amount = (invoice.totalAmount * 100).roundToDouble() / 100;
      // On a credit sale, the customer's debt is booked atomically with the
      // invoice (amount = total, linked back via invoiceId).
      final creditCharge = customerId == null
          ? null
          : LedgerEntriesCompanion(
              id: Value(const Uuid().v4()),
              customerId: Value(customerId),
              invoiceId: Value(invoice.id),
              entryType: const Value('charge'),
              amount: Value(amount),
              createdAt: Value(invoice.createdAt.millisecondsSinceEpoch),
            );
      // The inverse: a **cash** sale (no customer) posts a positive cashbox
      // entry, atomically with the invoice. Mutually exclusive with
      // creditCharge — a sale is either cash or credit, never both. Type is the
      // `CashTransactionType.cashSale` name string (kept as a literal here so
      // the billing layer needn't import the cashbox domain enum).
      final cashReceipt = customerId != null
          ? null
          : CashboxTransactionsCompanion(
              id: Value(const Uuid().v4()),
              type: const Value('cashSale'),
              amount: Value(amount),
              relatedId: Value(invoice.id),
              occurredAt: Value(invoice.createdAt.millisecondsSinceEpoch),
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
        cashReceipt: cashReceipt,
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
  Stream<List<InvoiceListItem>> watchFilteredInvoices(
    SalesFilter filter, {
    int limit = 30,
    int offset = 0,
  }) {
    return _dao
        .watchAuditInvoices(
          fromMs: filter.from.millisecondsSinceEpoch,
          toMs: filter.to.millisecondsSinceEpoch,
          payment: _paymentSql(filter.payment),
          search: filter.search.trim(),
          orderBySql: _orderBySql(filter.sort),
          limit: limit,
          offset: offset,
        )
        .map((rows) => rows
            .map((r) => InvoiceListItem(
                  id: r.id,
                  createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
                  total: r.totalAmount,
                  itemCount: r.itemCount,
                  isCredit: r.isCredit,
                  customerName: r.customerName,
                ))
            .toList());
  }

  @override
  Stream<SalesSummary> watchSummary(SalesFilter filter) {
    return _dao
        .watchAuditSummary(
          fromMs: filter.from.millisecondsSinceEpoch,
          toMs: filter.to.millisecondsSinceEpoch,
          payment: _paymentSql(filter.payment),
          search: filter.search.trim(),
        )
        .map((r) => SalesSummary(
              count: r.count,
              total: r.total,
              creditTotal: r.creditTotal,
              cashTotal: r.total - r.creditTotal,
            ));
  }

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
