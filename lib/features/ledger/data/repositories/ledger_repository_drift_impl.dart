import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/ledger_dao.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/repositories/ledger_repository.dart';

class LedgerRepositoryDriftImpl implements LedgerRepository {
  final LedgerDao _dao;

  const LedgerRepositoryDriftImpl(this._dao);

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
      await _dao.insertEntry(LedgerEntriesCompanion(
        id: Value(entry.id),
        customerId: Value(entry.customerId),
        invoiceId: Value(entry.invoiceId),
        entryType:
            Value(entry.type == LedgerEntryType.payment ? _payment : _charge),
        amount: Value(amount),
        note: Value(entry.note),
        createdAt: Value(entry.createdAt.millisecondsSinceEpoch),
      ));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEntry(String id) async {
    try {
      await _dao.deleteEntry(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
