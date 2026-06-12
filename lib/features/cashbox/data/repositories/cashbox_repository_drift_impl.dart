import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/cashbox_dao.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/cashbox_entry.dart';
import '../../domain/repositories/cashbox_repository.dart';
class CashboxRepositoryDriftImpl implements CashboxRepository {
  final CashboxDao _dao;
  const CashboxRepositoryDriftImpl(this._dao);
  @override
  Future<Either<Failure, List<CashboxEntry>>> getAllEntries() async {
    try {
      final rows = await _dao.getAllEntries();
      return Right(rows.map((r) => CashboxEntry(
        id: r.id, amount: r.amount, type: r.type,
        date: DateTime.fromMillisecondsSinceEpoch(r.date), notes: r.notes,
      )).toList());
    } catch (e) { return Left(CacheFailure(e.toString())); }
  }
  @override
  Future<Either<Failure, void>> addEntry(CashboxEntry entry) async {
    try {
      await _dao.insertEntry(CashboxEntriesCompanion(
        amount: Value(entry.amount), type: Value(entry.type),
        date: Value(entry.date.millisecondsSinceEpoch), notes: Value(entry.notes),
      ));
      return const Right(null);
    } catch (e) { return Left(CacheFailure(e.toString())); }
  }
  @override
  Future<Either<Failure, void>> deleteEntry(int id) async {
    try { await _dao.deleteEntry(id); return const Right(null); }
    catch (e) { return Left(CacheFailure(e.toString())); }
  }
}
