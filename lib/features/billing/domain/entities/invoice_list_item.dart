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

  /// The credit customer's id; null for a cash sale. Carried alongside the name
  /// because a payment correction (Plan 016 C-a) has to pre-select the customer
  /// it is about, and two customers may share a name.
  final String? customerId;

  const InvoiceListItem({
    required this.id,
    required this.createdAt,
    required this.total,
    required this.itemCount,
    required this.isCredit,
    this.customerName,
    this.customerId,
  });

  /// Only the *derived* payment fields are replaceable — that is the one thing
  /// about a recorded sale that can legitimately change (Plan 016 C-a). The id,
  /// date, total and item count belong to the invoice itself and never move.
  ///
  /// The customer is passed positively (null clears it) because switching to
  /// cash must drop the old name, not keep it via a `??` fallback.
  InvoiceListItem withPayment({
    required bool isCredit,
    String? customerName,
    String? customerId,
  }) =>
      InvoiceListItem(
        id: id,
        createdAt: createdAt,
        total: total,
        itemCount: itemCount,
        isCredit: isCredit,
        customerName: isCredit ? customerName : null,
        customerId: isCredit ? customerId : null,
      );

  @override
  List<Object?> get props =>
      [id, createdAt, total, itemCount, isCredit, customerName, customerId];
}
