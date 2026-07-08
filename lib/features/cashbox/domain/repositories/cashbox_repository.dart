import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/cash_transaction.dart';

abstract class CashboxRepository {
  /// All cash transactions, newest first (reactive).
  Stream<List<CashTransaction>> watchTransactions();

  /// Record a manual cash transaction (deposit, expense, adjustment, …).
  Future<Either<Failure, void>> addTransaction(CashTransaction tx);

  /// Remove a (manual) transaction.
  Future<Either<Failure, void>> deleteTransaction(String id);
}
