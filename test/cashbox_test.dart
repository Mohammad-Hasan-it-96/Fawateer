import 'package:billing_app/features/cashbox/domain/entities/cash_transaction.dart';
import 'package:billing_app/features/cashbox/domain/entities/cash_transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// The derived balance = signed sum of all transactions, rounded to 2 decimals
/// (mirrors CashboxBloc's in-memory derivation).
double _balance(List<CashTransaction> txs) {
  final raw = txs.fold<double>(0, (sum, t) => sum + t.amount);
  return (raw * 100).roundToDouble() / 100;
}

CashTransaction _tx(CashTransactionType type, double amount) {
  final now = DateTime(2026, 1, 1);
  return CashTransaction(
    id: '${type.name}-$amount',
    type: type,
    amount: amount,
    occurredAt: now,
    createdAt: now,
  );
}

void main() {
  group('CashTransactionType', () {
    test('persists and parses by name (reorder-safe)', () {
      for (final t in CashTransactionType.values) {
        expect(CashTransactionType.fromName(t.name), t);
      }
    });

    test('unknown/legacy name falls back to manualAdjustment', () {
      expect(CashTransactionType.fromName('does_not_exist'),
          CashTransactionType.manualAdjustment);
      expect(CashTransactionType.fromName(null),
          CashTransactionType.manualAdjustment);
    });

    test('default directions are correct', () {
      expect(CashTransactionType.cashSale.defaultDirection, CashDirection.inflow);
      expect(CashTransactionType.expense.defaultDirection, CashDirection.outflow);
      expect(CashTransactionType.manualAdjustment.defaultDirection,
          CashDirection.either);
    });

    test('only cash sale & debt payment are system-generated', () {
      expect(CashTransactionType.cashSale.isSystemGenerated, isTrue);
      expect(CashTransactionType.customerDebtPayment.isSystemGenerated, isTrue);
      expect(CashTransactionType.expense.isSystemGenerated, isFalse);
      expect(CashTransactionType.manualAdjustment.isSystemGenerated, isFalse);
    });
  });

  group('CashTransaction', () {
    test('sign drives isInflow / magnitude', () {
      final inflow = _tx(CashTransactionType.manualDeposit, 100);
      final outflow = _tx(CashTransactionType.expense, -40);
      expect(inflow.isInflow, isTrue);
      expect(outflow.isInflow, isFalse);
      expect(outflow.magnitude, 40);
    });
  });

  group('derived balance', () {
    test('signed sum; adjustment outflow subtracts', () {
      final txs = [
        _tx(CashTransactionType.openingBalance, 1000),
        _tx(CashTransactionType.cashSale, 250),
        _tx(CashTransactionType.expense, -75),
        _tx(CashTransactionType.manualAdjustment, -25), // outflow adjustment
      ];
      expect(_balance(txs), 1150);
    });

    test('rounds float noise to 2 decimals', () {
      final txs = [
        _tx(CashTransactionType.cashSale, 0.1),
        _tx(CashTransactionType.cashSale, 0.2),
      ];
      expect(_balance(txs), 0.3);
    });

    test('empty cashbox is zero', () {
      expect(_balance(const []), 0);
    });
  });
}
