import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/cashbox_dao.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/sync/sync_clock.dart';
import '../../domain/entities/cash_transaction.dart';
import '../../domain/entities/cash_transaction_type.dart';
import '../../domain/repositories/cashbox_repository.dart';

class CashboxRepositoryDriftImpl implements CashboxRepository {
  final CashboxDao _dao;
  final SyncClock _clock;

  const CashboxRepositoryDriftImpl(this._dao, this._clock);

  static CashTransaction _toEntity(CashboxTransactionRow r) => CashTransaction(
        id: r.id,
        type: CashTransactionType.fromName(r.type),
        amount: r.amount,
        note: r.note,
        relatedId: r.relatedId,
        occurredAt: DateTime.fromMillisecondsSinceEpoch(r.occurredAt),
        createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
      );

  @override
  Stream<List<CashTransaction>> watchTransactions() =>
      _dao.watchTransactions().map((rows) => rows.map(_toEntity).toList());

  @override
  Future<Either<Failure, void>> addTransaction(CashTransaction tx) async {
    try {
      // Round to currency precision at write time (money stays double app-wide,
      // but we don't want raw float noise accumulating in a running balance).
      // The idiom works for negative amounts too.
      final amount = (tx.amount * 100).roundToDouble() / 100;
      final stamp = await _clock.stamp();
      await _dao.insertTransaction(CashboxTransactionsCompanion(
        id: Value(tx.id),
        type: Value(tx.type.name),
        amount: Value(amount),
        note: Value(tx.note),
        relatedId: Value(tx.relatedId),
        occurredAt: Value(tx.occurredAt.millisecondsSinceEpoch),
        createdAt: Value(tx.createdAt.millisecondsSinceEpoch),

        // **The sync stamp, on every write.** Without it `updated_at` stays ''
        // — the "predates sync, never push me" marker — so the row is silently
        // invisible to `SyncDao.collectSince` and never leaves this phone. That
        // was the shipped state: deletes and sales were stamped, ordinary
        // creates and edits were not, so a shop could add a product on one till
        // and watch the other till never hear about it while every screen
        // reported success (found in a two-phone field test, 2026-09-01).
        updatedAt: Value(stamp.hlc),
        originDevice: Value(stamp.device),
      ));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String id) async {
    try {
      await _dao.softDeleteTransaction(id, await _clock.stamp());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
