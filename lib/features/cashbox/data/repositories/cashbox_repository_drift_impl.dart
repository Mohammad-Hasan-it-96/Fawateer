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
      await _dao.insertTransaction(CashboxTransactionsCompanion(
        id: Value(tx.id),
        type: Value(tx.type.name),
        amount: Value(amount),
        note: Value(tx.note),
        relatedId: Value(tx.relatedId),
        occurredAt: Value(tx.occurredAt.millisecondsSinceEpoch),
        createdAt: Value(tx.createdAt.millisecondsSinceEpoch),
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
