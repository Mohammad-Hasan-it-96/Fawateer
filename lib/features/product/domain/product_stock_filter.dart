import '../../../l10n/app_localizations.dart';
import 'entities/product.dart';

/// The quick stock-status filter on the products page (Plan 013 #1).
///
/// An enum rather than two booleans, because the three states are mutually
/// exclusive and a boolean pair can represent "out of stock AND low stock",
/// which is not a thing — the project's standing preference for extensible
/// enums over flags.
///
/// Reuses the predicates the product list already renders as chips, so the
/// filter and the badge can never disagree about what "out of stock" means.
enum ProductStockFilter {
  all,

  /// `quantity <= 0`, for every product — **not** gated on a minimum being set.
  /// The shop wants zero flagged whether or not they track that item, which is
  /// what `Product.isOutOfStock` already decided (Plan 011 #8).
  outOfStock,

  /// At or under the owner's own threshold. Only meaningful for products where
  /// `minStockAlert > 0`, i.e. the ones the shop chose to track — which is
  /// usually a small minority of the catalogue.
  lowStock;

  bool matches(Product p) => switch (this) {
        ProductStockFilter.all => true,
        ProductStockFilter.outOfStock => p.isOutOfStock,
        // Deliberately excludes items already at zero: they are shown by the
        // other chip, and a shopkeeper filtering for "running low" is looking
        // for what to reorder *before* it runs out.
        ProductStockFilter.lowStock => p.isLowStock && !p.isOutOfStock,
      };

  String label(AppLocalizations l10n) => switch (this) {
        ProductStockFilter.all => l10n.filterAll,
        ProductStockFilter.outOfStock => l10n.outOfStockBadge,
        ProductStockFilter.lowStock => l10n.lowStockBadge,
      };
}
