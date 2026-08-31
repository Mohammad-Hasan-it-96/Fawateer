import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/cashbox_dao.dart';
import '../../../../core/database/daos/ledger_dao.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/sync/sync_clock.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/repositories/ledger_repository.dart';

class LedgerRepositoryDriftImpl implements LedgerRepository {
  final LedgerDao _dao;

  /// For transactions that span the ledger and the cashbox (a debt repayment
  /// received in cash posts to both atomically).
  final AppDatabase _db;
  final CashboxDao _cashboxDao;

  final SyncClock _clock;

  const LedgerRepositoryDriftImpl(
      this._dao, this._db, this._cashboxDao, this._clock);

  static const _charge = 'charge';
  static const _payment = 'payment';

  static LedgerEntry _toEntity(LedgerEntryRow r) => LedgerEntry(
        id: r.id,
        customerId: r.customerId,
        invoiceId: r.invoiceId,
        type: r.entryType == _payment
            ? LedgerEntryType.payment
            : LedgerEntryType.charge,
        amount: r.amount,
        note: r.note,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
      );

  @override
  Stream<List<LedgerEntry>> watchEntries(String customerId) =>
      _dao.watchEntries(customerId).map((rows) => rows.map(_toEntity).toList());

  @override
  Stream<double> watchBalance(String customerId) =>
      _dao.watchBalance(customerId);

  @override
  Future<Either<Failure, void>> addEntry(LedgerEntry entry) async {
    try {
      // Round to currency precision at write time (money stays double app-wide,
      // but we don't want raw float noise accumulating in a running balance).
      final amount = (entry.amount * 100).roundToDouble() / 100;
      final isPayment = entry.type == LedgerEntryType.payment;
      // One stamp for the whole act, exactly as `deleteEntry` takes one for
      // the entry and its reversal: a repayment and the cash it put in the
      // drawer are the same event, and giving them different positions would
      // be a lie the merge could act on.
      final stamp = await _clock.stamp();
      final ledgerCompanion = LedgerEntriesCompanion(
        id: Value(entry.id),
        customerId: Value(entry.customerId),
        invoiceId: Value(entry.invoiceId),
        entryType: Value(isPayment ? _payment : _charge),
        amount: Value(amount),
        note: Value(entry.note),
        createdAt: Value(entry.createdAt.millisecondsSinceEpoch),
        // The sync stamp: without it `updated_at` stays '' and the row is
        // never pushed. See the note in ProductRepositoryDriftImpl.
        updatedAt: Value(stamp.hlc),
        originDevice: Value(stamp.device),
      );

      if (isPayment) {
        // A debt repayment is money received in cash: post the ledger `payment`
        // and a positive cashbox entry in one transaction so the two can't
        // diverge. The cashbox entry links back via relatedId = ledger entry id
        // (so deleting the payment reverses it). Type is the
        // `CashTransactionType.customerDebtPayment` name string (kept literal so
        // the ledger layer needn't import the cashbox domain enum).
        await _db.transaction(() async {
          await _dao.insertEntry(ledgerCompanion);
          await _cashboxDao.insertTransaction(CashboxTransactionsCompanion(
            id: Value('cash-${entry.id}'),
            type: const Value('customerDebtPayment'),
            amount: Value(amount),
            relatedId: Value(entry.id),
            occurredAt: Value(entry.createdAt.millisecondsSinceEpoch),
            createdAt: Value(entry.createdAt.millisecondsSinceEpoch),
            updatedAt: Value(stamp.hlc),
            originDevice: Value(stamp.device),
          ));
        });
      } else {
        await _dao.insertEntry(ledgerCompanion);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEntry(String id) async {
    try {
      // Tombstone the entry and reverse any cashbox entry it posted (a debt
      // payment) in one transaction. softDeleteByRelatedId is a no-op for a
      // charge (which posts no cash), so this is safe for either entry type.
      //
      // One stamp for both writes, taken outside the transaction: they are a
      // single logical act, and giving the reversal a later timestamp than the
      // deletion it reverses would be a lie the merge could act on.
      final stamp = await _clock.stamp();
      await _db.transaction(() async {
        await _dao.softDeleteEntry(id, stamp);
        await _cashboxDao.softDeleteByRelatedId(id, stamp);
      });
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
