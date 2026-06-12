import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/cashbox_entry.dart';

abstract class CashboxRepository {
  Future<Either<Failure, List<CashboxEntry>>> getAllEntries();
  Future<Either<Failure, void>> addEntry(CashboxEntry entry);
  Future<Either<Failure, void>> deleteEntry(int id);
}

