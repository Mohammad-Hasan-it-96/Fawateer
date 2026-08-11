import 'entities/product.dart';

/// Which products are currently low (Plan 013 #10).
///
/// [Product.isLowStock] already carries the rule: `minStockAlert > 0 &&
/// quantity <= minStockAlert`. The threshold **is** the opt-in — a shop that
/// never set one for a product has said it doesn't count that item, and loose
/// produce sitting at zero forever must never generate alerts.
Set<String> lowStockIds(Iterable<Product> products) =>
    products.where((p) => p.isLowStock).map((p) => p.id).toSet();

/// The products that just *became* low — the ones worth interrupting someone
/// for.
///
/// Alerting on the state rather than the transition is the obvious version and
/// the wrong one: the product list re-emits after **every sale**, so an
/// already-low item would notify again on every single scan until it was
/// restocked, and the shop would turn alerts off within an hour.
///
/// [announced] is what has already been reported. A product that is restocked
/// leaves that set, so it can legitimately alert again the next time it runs
/// down — which is the whole point of a reorder reminder.
/// Note there is no separate "what should I remember" helper: what gets
/// remembered is simply [lowStockIds] of the latest list. A restocked product
/// falls out of it on its own, which is what lets it alert again later.
Set<String> newlyLowIds(Iterable<Product> products, Set<String> announced) =>
    lowStockIds(products).difference(announced);
