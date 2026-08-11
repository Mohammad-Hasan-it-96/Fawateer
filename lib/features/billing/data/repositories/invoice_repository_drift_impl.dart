import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/sales_dao.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/sync/sync_clock.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/entities/invoice_list_item.dart';
import '../../domain/entities/sales_filter.dart';
import '../../domain/entities/sales_summary.dart';
import '../../domain/repositories/invoice_repository.dart';

class InvoiceRepositoryDriftImpl implements InvoiceRepository {
  final SalesDao _dao;
  final SyncClock _clock;
  const InvoiceRepositoryDriftImpl(this._dao, this._clock);

  static Invoice _toEntity(SalesInvoiceRow r) => Invoice(
        id: r.id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
        totalAmount: r.totalAmount,
        invoiceDiscount: r.invoiceDiscount,
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
      {String? customerId, List<String> soldUnitIds = const []}) async {
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
          invoiceDiscount: Value(invoice.invoiceDiscount),
        ),
        stamp: await _clock.stamp(),
        items: [
          for (final (index, i) in items.indexed)
            SalesItemsCompanion(
              // The line's device-independent sync id. `sales_items.id` is a
              // local autoincrement, so two devices mint id=1 for different
              // lines. Same deterministic shape the v16 backfill gave
              // historical rows, and the stock movement is keyed off it, so a
              // sale that arrives twice cannot deduct the stock twice.
              uuid: Value('${invoice.id}-$index'),
              invoiceId: Value(invoice.id),
              productId: Value(i.productId),
              productName: Value(i.productName),
              price: Value(i.price),
              cost: Value(i.cost),
              quantity: Value(i.quantity),
              priceCurrency: Value(i.priceCurrency),
              fxRate: Value(i.fxRate),
              priceOriginal: Value(i.priceOriginal),
              discount: Value(i.discount),
              attributesSnapshot: Value(i.attributesSnapshot),
              saleType: Value(i.saleType),
              serialSnapshot: Value(i.serialSnapshot),
            ),
        ],
        creditCharge: creditCharge,
        cashReceipt: cashReceipt,
        soldUnitIds: soldUnitIds,
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
                  customerId: r.customerId,
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
              profit: r.profit,
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
                priceCurrency: r.priceCurrency,
                fxRate: r.fxRate,
                priceOriginal: r.priceOriginal,
                discount: r.discount,
                attributesSnapshot: r.attributesSnapshot,
                saleType: r.saleType,
                serialSnapshot: r.serialSnapshot,
              ))
          .toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changeInvoicePayment(
    String invoiceId, {
    required String? customerId,
  }) async {
    try {
      // The uuid is minted here, matching `saveInvoice` above — the DAO stays
      // free of id generation, and the row it writes (cash entry or ledger
      // charge) is decided by `customerId` exactly as it is on the sale path.
      final result = await _dao.setInvoicePayment(
        invoiceId: invoiceId,
        customerId: customerId,
        newRowId: const Uuid().v4(),
        stamp: await _clock.stamp(),
      );
      switch (result) {
        case PaymentChangeResult.ok:
          return const Right(null);
        case PaymentChangeResult.invoiceMissing:
          return const Left(NotFoundFailure('invoice not found'));
        case PaymentChangeResult.customerMissing:
          return const Left(NotFoundFailure('customer not found'));
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInvoice(String id) async {
    try {
      await _dao.softDeleteInvoice(id, await _clock.stamp());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
