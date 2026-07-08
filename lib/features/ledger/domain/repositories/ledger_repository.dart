import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/ledger_entry.dart';

abstract class LedgerRepository {
  /// A customer's entries, newest first (reactive).
  Stream<List<LedgerEntry>> watchEntries(String customerId);

  /// The customer's reactive derived balance (positive = owes the shop).
  Stream<double> watchBalance(String customerId);

  /// Record a manual charge or payment.
  Future<Either<Failure, void>> addEntry(LedgerEntry entry);

  /// Remove an entry (to correct a mistake).
  Future<Either<Failure, void>> deleteEntry(String id);
}
