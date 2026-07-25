import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';
import '../../domain/product_search.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../core/utils/format.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../attributes/presentation/bloc/attribute_definition_bloc.dart';
import '../../../attributes/domain/entities/attribute_definition.dart';
import '../../../attributes/domain/entities/attribute_type.dart';
import '../../../../l10n/app_localizations.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

/// Map a [ProductMessage] to a localized, user-facing string.
String _productMessageText(ProductMessage m, AppLocalizations l10n) {
  switch (m) {
    case ProductMessage.added:
      return l10n.productAdded;
    case ProductMessage.updated:
      return l10n.productUpdated;
    case ProductMessage.deleted:
      return l10n.productDeleted;
    case ProductMessage.barcodeExists:
      return l10n.barcodeExistsError;
    case ProductMessage.saveFailed:
      return l10n.errorSaveFailed;
    case ProductMessage.loadFailed:
      return l10n.errorLoadFailed;
    case ProductMessage.labelPrinted:
      return l10n.labelPrinted;
    case ProductMessage.labelPrintFailed:
      return l10n.labelPrintFailed;
  }
}

class _ProductListPageState extends State<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// Active custom-field filters (Plan 010): definitionId → selected option
  /// values. A product passes when, for every entry, its value for that field
  /// is in the selected set (AND across fields, OR within a field). Runs in
  /// Dart over the in-memory product list — no index/DB query.
  final Map<String, Set<String>> _attrFilters = {};

  int get _activeFilterCount =>
      _attrFilters.values.fold(0, (n, s) => n + s.length);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _scanQR(List<Product> products) async {
    final barcode = await context.push<String>('/scanner');
    if (barcode != null && barcode.isNotEmpty) {
      final matchedProduct =
          products.where((p) => p.barcode == barcode).firstOrNull;
      if (matchedProduct != null) {
        _searchController.text = matchedProduct.name;
      } else {
        _searchController.text = barcode;
      }
    }
  }

  bool _matchesFilters(Product product) => productMatchesSearch(product,
      query: _searchQuery, attrFilters: _attrFilters);

  void _openFilterSheet(
      List<AttributeDefinition> selectDefs, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            void toggle(String defId, String opt, bool selected) {
              setState(() {
                final set = _attrFilters.putIfAbsent(defId, () => <String>{});
                if (selected) {
                  set.add(opt);
                } else {
                  set.remove(opt);
                }
                if (set.isEmpty) _attrFilters.remove(defId);
              });
              setSheet(() {});
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(l10n.filterProductsTitle,
                              style:
                                  Theme.of(sheetCtx).textTheme.titleMedium),
                        ),
                        if (_activeFilterCount > 0)
                          TextButton(
                            onPressed: () {
                              setState(() => _attrFilters.clear());
                              setSheet(() {});
                            },
                            child: Text(l10n.clearFiltersBtn),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final def in selectDefs) ...[
                              Text(def.label,
                                  style: Theme.of(sheetCtx)
                                      .textTheme
                                      .labelLarge),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  for (final opt in def.options)
                                    FilterChip(
                                      label: Text(opt),
                                      selected: _attrFilters[def.id]
                                              ?.contains(opt) ??
                                          false,
                                      onSelected: (sel) =>
                                          toggle(def.id, opt, sel),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).dividerColor;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(l10n.productsTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _searchController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: l10n.searchHint,
                            prefixIcon: Icon(
                              Icons.search,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          validator: AppValidators.required(l10n.fieldRequired),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.qr_code_scanner,
                              color: AppTheme.primaryColor),
                          onPressed: () => _scanQR(state.products),
                          padding: const EdgeInsets.all(15),
                        ),
                      ),
                      // Custom-field filter (Plan 010): shown only when the shop
                      // has a choice-list field to filter by.
                      Builder(builder: (context) {
                        final selectDefs = context
                            .watch<AttributeDefinitionBloc>()
                            .state
                            .active
                            .where((d) =>
                                d.type == AttributeType.select &&
                                d.options.isNotEmpty)
                            .toList();
                        if (selectDefs.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.tune,
                                      color: AppTheme.primaryColor),
                                  onPressed: () =>
                                      _openFilterSheet(selectDefs, l10n),
                                  padding: const EdgeInsets.all(15),
                                ),
                                if (_activeFilterCount > 0)
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                          minWidth: 18, minHeight: 18),
                                      child: Text(
                                        '$_activeFilterCount',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(l10n.tapToScan,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              );
            }),
          ),

          Expanded(
            child: BlocConsumer<ProductBloc, ProductState>(
              listener: (context, state) {
                final message = state.message;
                if (message == null) return;
                final isError = state.status == ProductStatus.error;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_productMessageText(message, l10n)),
                    backgroundColor: isError ? Colors.red : Colors.green,
                  ),
                );
              },
              builder: (context, state) {
                if (state.status == ProductStatus.loading &&
                    state.products.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.products.isEmpty) {
                  if (state.status == ProductStatus.error) {
                    return Center(
                        child: Text(_productMessageText(
                            state.message ?? ProductMessage.loadFailed, l10n)));
                  }
                  return Center(child: Text(l10n.noProductsFound));
                }

                final filteredProducts =
                    state.products.where(_matchesFilters).toList();

                if (filteredProducts.isEmpty) {
                  return Center(child: Text(l10n.noProductsMatch));
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 8, bottom: 100),
                  itemCount: filteredProducts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Builder(builder: (context) {
                                  final shopState =
                                      context.watch<ShopBloc>().state;
                                  final currency = shopState is ShopLoaded
                                      ? shopState.shop.currencySymbol
                                      : '';
                                  return Text(
                                    product.priceCurrency
                                        .label(product.price, currency),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                                  );
                                }),
                                Builder(builder: (context) {
                                  // Custom-field subtitle (Plan 010): only the
                                  // fields the owner flagged showInList, with a
                                  // value on this product.
                                  final defs = context
                                      .watch<AttributeDefinitionBloc>()
                                      .state
                                      .active
                                      .where((d) => d.showInList);
                                  final bits = <String>[];
                                  for (final d in defs) {
                                    final v = product.attributes[d.id];
                                    if (v == null || v.isEmpty) continue;
                                    bits.add(d.unit.isEmpty ? v : '$v ${d.unit}');
                                  }
                                  if (bits.isEmpty) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      bits.join(' · '),
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                    ),
                                  );
                                }),
                                if (product.minStockAlert > 0 ||
                                    product.quantity > 0) ...[
                                  const SizedBox(height: 8),
                                  _buildStockRow(context, product, l10n),
                                ],
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.print_rounded,
                                      color: AppTheme.primaryColor, size: 22),
                                  tooltip: l10n.printLabelTitle,
                                  constraints: const BoxConstraints(
                                      minWidth: 48, minHeight: 48),
                                  onPressed: () => _printLabel(context, product),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.edit_rounded,
                                      color: AppTheme.primaryColor, size: 22),
                                  constraints: const BoxConstraints(
                                      minWidth: 48, minHeight: 48),
                                  onPressed: () {
                                    context.push('/products/edit/${product.id}',
                                        extra: product);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: Colors.red, size: 22),
                                  constraints: const BoxConstraints(
                                      minWidth: 48, minHeight: 48),
                                  onPressed: () =>
                                      _confirmDelete(context, product),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/products/add'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  /// On-hand quantity plus a red chip when the product is running low — or a
  /// stronger red "out of stock" chip when a stock-tracked item has hit zero
  /// (Plan 011 #8) — so the owner sees a finished item at a glance instead of
  /// hunting the shelf.
  Widget _buildStockRow(
      BuildContext context, Product product, AppLocalizations l10n) {
    final out = product.isOutOfStock;
    // Out-of-stock supersedes the softer low-stock chip.
    final low = product.isLowStock && !out;
    final alert = out || low;
    return Row(
      children: [
        Icon(out ? Icons.production_quantity_limits : Icons.inventory_2_outlined,
            size: 16,
            color: alert
                ? Colors.red
                : Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          l10n.stockCountLabel(formatQty(product.quantity)),
          style: TextStyle(
            fontSize: 13,
            fontWeight: alert ? FontWeight.bold : FontWeight.w500,
            color: alert
                ? Colors.red
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (alert) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(out ? Icons.remove_shopping_cart : Icons.warning_amber_rounded,
                    size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Text(out ? l10n.outOfStockBadge : l10n.lowStockBadge,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (innerContext) {
        return AlertDialog(
          title: Text(l10n.deleteProductTitle),
          content: Text(l10n.deleteProductConfirm(product.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(innerContext),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                context.read<ProductBloc>().add(DeleteProduct(product.id));
                Navigator.pop(innerContext);
              },
              child: Text(l10n.delete,
                  style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// Print label(s) for a product (Plan 010): a small dialog for the copy count
  /// and — when the product has a barcode — the code type (barcode vs QR), then
  /// dispatch to [ProductBloc]. The printed price is currency-aware.
  void _printLabel(BuildContext context, Product product) {
    final l10n = AppLocalizations.of(context)!;
    final shopState = context.read<ShopBloc>().state;
    final currency =
        shopState is ShopLoaded ? shopState.shop.currencySymbol : '';
    final priceText = product.priceCurrency.label(product.price, currency);

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        int copies = 1;
        bool useQr = false;
        return StatefulBuilder(
          builder: (dialogCtx, setDialog) {
            return AlertDialog(
              title: Text(l10n.printLabelTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(priceText,
                      style: TextStyle(
                          color:
                              Theme.of(dialogCtx).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(l10n.labelCopies),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: copies > 1
                            ? () => setDialog(() => copies--)
                            : null,
                      ),
                      Text('$copies',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: copies < 99
                            ? () => setDialog(() => copies++)
                            : null,
                      ),
                    ],
                  ),
                  if (product.barcode.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                            value: false, label: Text(l10n.labelBarcode)),
                        ButtonSegment(value: true, label: Text(l10n.labelQr)),
                      ],
                      selected: {useQr},
                      onSelectionChanged: (s) =>
                          setDialog(() => useQr = s.first),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(l10n.cancel),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    context.read<ProductBloc>().add(PrintProductLabel(
                          name: product.name,
                          priceText: priceText,
                          barcodeData: product.barcode,
                          useQr: useQr,
                          copies: copies,
                        ));
                  },
                  icon: const Icon(Icons.print, size: 18),
                  label: Text(l10n.printLabelAction),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
