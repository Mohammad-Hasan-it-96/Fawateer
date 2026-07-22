import 'package:equatable/equatable.dart';

/// A row in the Sales History / audit list. Richer than [Invoice] (the lean
/// write-path model): it carries the *derived* fields the audit center needs —
/// payment type and the customer — which are NOT stored on `sales_invoices` but
/// joined in at query time (credit ⇒ a `ledger_entries` charge row for this
/// invoice, which also gives the customer; cash ⇒ anonymous).
class InvoiceListItem extends Equatable {
  final String id;
  final DateTime createdAt;
  final double total;
  final int itemCount;

  /// True when the sale was on credit (a linked ledger `charge` exists); false
  /// for a cash sale.
  final bool isCredit;

  /// The customer's name for a credit sale; null for a cash (anonymous) sale.
  final String? customerName;

  const InvoiceListItem({
    required this.id,
    required this.createdAt,
    required this.total,
    required this.itemCount,
    required this.isCredit,
    this.customerName,
  });

  @override
  List<Object?> get props =>
      [id, createdAt, total, itemCount, isCredit, customerName];
}
