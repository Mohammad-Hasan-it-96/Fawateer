import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../attributes/domain/attribute_options.dart';
import '../../../attributes/domain/product_category.dart';
import '../../domain/bulk_price_edit.dart';
import '../../domain/product_search.dart';
import '../../domain/product_stock_filter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/num_input.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../attributes/presentation/bloc/attribute_definition_bloc.dart';
import '../../../attributes/domain/entities/attribute_definition.dart';
import '../../../attributes/domain/entities/attribute_type.dart';
import '../../../../l10n/app_localizations.dart';

class ProductListPage extends StatefulWidget {
  /// Pre-applied stock filter, set when another screen navigates here to answer
  /// a specific question — the Reports low-stock card's "show all"
  /// (Plan 013 #1). Null means the normal entry through the tab.
  final ProductStockFilter? initialStockFilter;

  const ProductListPage({super.key, this.initialStockFilter});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

/// Map a [ProductMessage] to a localized, user-facing string.
String _productMessageText(ProductMessage m, AppLocalizations l10n,
    [int count = 0]) {
  switch (m) {
    case ProductMessage.bulkPricesUpdated:
      return l10n.bulkPricesUpdated(count);
    case ProductMessage.bulkPricesUnchanged:
      return l10n.bulkPricesUnchanged;
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
    case ProductMessage.bulkCategorySet:
      return l10n.bulkCategorySet(count);
  }
}

/// The two tabs the owner asked for (Plan 014). Not a `TabBar`: this page's
/// header is already search + filters + chips, and a real tab bar would add a
/// third band of chrome above a list that needs the room.
enum _ProductView { all, byCategory }

class _ProductListPageState extends State<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// Active custom-field filters (Plan 010): definitionId → selected option
  /// values. A product passes when, for every entry, its value for that field
  /// is in the selected set (AND across fields, OR within a field). Runs in
  /// Dart over the in-memory product list — no index/DB query.
  final Map<String, Set<String>> _attrFilters = {};

  /// Quick stock-status filter (Plan 013 #1). A chip row rather than another
  /// entry in the filter sheet: "what has run out?" is the question a shop asks
  /// while standing at the shelf, and it should not be two taps behind an icon.
  late ProductStockFilter _stockFilter =
      widget.initialStockFilter ?? ProductStockFilter.all;

  int get _activeFilterCount =>
      _attrFilters.values.fold(0, (n, s) => n + s.length);

  /// Which tab is showing, and — in the category tab — which category is
  /// picked. `null` means "all categories"; `''` is the **أخرى** bucket, which
  /// needs no sentinel because `ProductAttributes` never stores a blank value
  /// (see `isUncategorized`).
  _ProductView _view = _ProductView.all;
  String? _category;

  /// The shop's category field, or null if it has not been created yet.
  AttributeDefinition? _categoryField(BuildContext context) => categoryFieldOf(
      context.watch<AttributeDefinitionBloc>().state.active);

  /// Multi-select (Plan 013's shared building block). One selection mechanism,
  /// meant to grow several actions: bulk price/cost today (Plan 015 B2.2), bulk
  /// category assign next (Plan 014 step 2).
  ///
  /// **Ids, not products.** The list is stream-backed and re-emits on every
  /// sale, so holding `Product` objects would mean comparing against copies
  /// that go stale the moment stock moves — the selection would quietly empty
  /// itself while the cashier was choosing.
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;

  /// The selection deliberately **survives a filter or search change**
  /// (Plan 015 B2.3 leaves this open; this is the choice). Picking six juices
  /// under one search and four under another is the actual job, and wiping the
  /// selection when the text field changes would make that impossible.
  ///
  /// The price of that choice is that some selected products can be off-screen,
  /// so the action bar says how many — an action that silently touches rows the
  /// owner cannot see is the thing to avoid here.
  void _toggleSelected(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
      if (_selectedIds.isEmpty) _selectionMode = false;
    });
  }

  void _startSelection(String id) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

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

  bool _matchesFilters(Product product) {
    if (!_stockFilter.matches(product)) return false;
    if (_view == _ProductView.byCategory && _category != null) {
      if ((product.attributes[kCategoryFieldId] ?? '') != _category) {
        return false;
      }
    }
    return productMatchesSearch(product,
        query: _searchQuery, attrFilters: _attrFilters);
  }

  /// The stock-status chips.
  ///
  /// **Low stock only means something once a minimum is set**, and most shops
  /// never set one — so that chip can look empty and broken on a perfectly
  /// healthy catalogue. The empty state below says so rather than leaving the
  /// owner to guess.
  Widget _stockFilterChips(AppLocalizations l10n) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final filter in ProductStockFilter.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(filter.label(l10n)),
                selected: _stockFilter == filter,
                onSelected: (_) => setState(() => _stockFilter = filter),
              ),
            ),
        ],
      ),
    );
  }

  /// الكل / حسب التصنيف. Switching back to "all" drops the picked category —
  /// otherwise the list stays silently filtered by a chip that is no longer on
  /// screen, which reads as "half my products disappeared".
  Widget _viewToggle(AppLocalizations l10n) {
    return SegmentedButton<_ProductView>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
            value: _ProductView.all, label: Text(l10n.tabAllProducts)),
        ButtonSegment(
            value: _ProductView.byCategory, label: Text(l10n.tabByCategory)),
      ],
      selected: {_view},
      onSelectionChanged: (s) => setState(() {
        _view = s.first;
        if (_view == _ProductView.all) _category = null;
      }),
    );
  }

  /// The category chips: **all**, one per option in the owner's order, then
  /// **أخرى**.
  ///
  /// Two things this must not do. It must not sort the options alphabetically —
  /// Arabic alphabetical order has nothing to do with how a shopkeeper thinks
  /// about their shelves, so the owner's own order stands. And it must not hide
  /// the uncategorised products: a shop of 300 items will categorise 40, and
  /// the other 260 have to stay reachable.
  Widget _categoryChips(AttributeDefinition field, AppLocalizations l10n) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final entry in <(String?, String)>[
                  (null, l10n.categoryAllChip),
                  ...field.options.map((o) => (o, o)),
                  ('', l10n.categoryUncategorized),
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(entry.$2),
                      selected: _category == entry.$1,
                      onSelected: (_) =>
                          setState(() => _category = entry.$1),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: l10n.manageCategoriesTooltip,
            // `go`, not `push`: this route lives in the Settings branch, and
            // pushing it from the Products branch would build it in a navigator
            // that is not on screen. Same precedent as the Reports card's
            // jump to /products.
            onPressed: () => context.go('/settings/product-fields'),
          ),
        ],
      ),
    );
  }

  /// Shown in the category tab before the shop has any categories.
  ///
  /// A tab that is simply empty reads as broken, so this both explains and
  /// creates. The categories are **typed by the owner** rather than seeded from
  /// a guess: a phone shop and a grocery share no sections, and starting
  /// someone with six wrong ones means six deletions before any use.
  Widget _noCategoriesState(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 32).clamp(0.0, 4000.0)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.category_outlined,
                  size: 56,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(l10n.noCategoriesTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(l10n.noCategoriesHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _openCreateCategories(l10n),
                icon: const Icon(Icons.add),
                label: Text(l10n.createCategoriesBtn),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One dialog that creates the category field and its first options, so the
  /// feature starts working without a trip to Settings.
  void _openCreateCategories(AppLocalizations l10n) {
    final bloc = context.read<AttributeDefinitionBloc>();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        var typed = '';
        return StatefulBuilder(
          builder: (dialogCtx, setDialog) => AlertDialog(
            title: Text(l10n.categoriesDialogTitle),
            content: TextField(
              autofocus: true,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.categoriesDialogHint,
                hintText: 'مشروبات، ألبان، تنظيف',
              ),
              onChanged: (v) => setDialog(() => typed = v),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: _splitOptions(typed).isEmpty
                    ? null
                    : () {
                        bloc.add(SaveDefinition(
                            newCategoryField(_splitOptions(typed))));
                        Navigator.pop(dialogCtx);
                      },
                child: Text(l10n.saveChangesBtn),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Split a comma-separated list, accepting both the Arabic comma (،) and the
  /// Latin one — the same rule the field editor in Settings uses, because a
  /// shopkeeper's keyboard produces whichever one it feels like.
  static List<String> _splitOptions(String raw) => raw
      .split(RegExp(r'[,،]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

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
                              style: Theme.of(sheetCtx).textTheme.titleMedium),
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
                                  style:
                                      Theme.of(sheetCtx).textTheme.labelLarge),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  for (final opt in def.options)
                                    FilterChip(
                                      label: Text(opt),
                                      selected:
                                          _attrFilters[def.id]?.contains(opt) ??
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

    // Back exits selection first (the Android habit), and only then falls
    // through to the shell's own back handling. `canPop` is true whenever
    // nothing is selected, so the normal tab-root behaviour — back goes to the
    // POS tab, see AppShell — is untouched.
    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectionMode) _exitSelection();
      },
      child: Scaffold(
        appBar: _selectionMode
            ? _selectionAppBar(l10n)
            : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Text(l10n.productsTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                centerTitle: true,
                actions: [
                  // Long-press is the habit, but it is invisible — a shopkeeper
                  // who has never long-pressed a list will never find bulk
                  // editing. This button is the discoverable door to the same
                  // mode.
                  IconButton(
                    icon: const Icon(Icons.checklist_rtl),
                    tooltip: l10n.selectAction,
                    onPressed: () => setState(() => _selectionMode = true),
                  ),
                ],
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
                    SizedBox(width: double.infinity, child: _viewToggle(l10n)),
                    const SizedBox(height: 8),
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
                            validator:
                                AppValidators.required(l10n.fieldRequired),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.05),
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
                          if (selectDefs.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.05),
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
                    const SizedBox(height: 8),
                    // One chip row, not two. In the category tab the categories
                    // *are* the filter on show; stacking the stock chips under
                    // them would push the first product off a small screen —
                    // the header is already four bands deep.
                    if (_view == _ProductView.byCategory)
                      Builder(builder: (context) {
                        final field = _categoryField(context);
                        return field == null
                            ? const SizedBox.shrink()
                            : _categoryChips(field, l10n);
                      })
                    else ...[
                      _stockFilterChips(l10n),
                      const SizedBox(height: 6),
                      Text(l10n.tapToScan,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ],
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
                      content: Text(_productMessageText(
                          message, l10n, state.messageCount)),
                      backgroundColor: isError ? Colors.red : Colors.green,
                    ),
                  );
                },
                builder: (context, state) {
                  // The category tab with no categories yet: explain and offer
                  // to create them, rather than showing an unexplained list.
                  if (_view == _ProductView.byCategory &&
                      _categoryField(context) == null) {
                    return _noCategoriesState(l10n);
                  }
                  if (state.status == ProductStatus.loading &&
                      state.products.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.products.isEmpty) {
                    if (state.status == ProductStatus.error) {
                      return Center(
                          child: Text(_productMessageText(
                              state.message ?? ProductMessage.loadFailed,
                              l10n)));
                    }
                    return Center(child: Text(l10n.noProductsFound));
                  }

                  final filteredProducts =
                      state.products.where(_matchesFilters).toList();

                  if (filteredProducts.isEmpty) {
                    // An empty "low stock" list usually means nobody has set a
                    // minimum, not that everything is well stocked. Saying "no
                    // products match" there sends the owner looking for a bug.
                    final noMinimumsSet =
                        _stockFilter == ProductStockFilter.lowStock &&
                            state.products.every((p) => p.minStockAlert <= 0);
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          noMinimumsSet
                              ? l10n.noLowStockThresholds
                              : l10n.noProductsMatch,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 8, bottom: 100),
                    itemCount: filteredProducts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final selected = _selectedIds.contains(product.id);
                      return GestureDetector(
                        // Long-press starts selection (the Android habit); once
                        // in, a plain tap toggles. Outside selection mode a tap
                        // on the card does nothing — the row's own buttons still
                        // own edit/print/delete, so nothing was taken away.
                        onLongPress: () => _startSelection(product.id),
                        onTap: _selectionMode
                            ? () => _toggleSelected(product.id)
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.primaryColor.withValues(alpha: 0.08)
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: selected
                                    ? AppTheme.primaryColor
                                    : borderColor,
                                width: selected ? 2 : 1),
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
                              if (_selectionMode)
                                Padding(
                                  padding:
                                      const EdgeInsetsDirectional.only(end: 8),
                                  child: Checkbox(
                                    value: selected,
                                    onChanged: (_) =>
                                        _toggleSelected(product.id),
                                  ),
                                ),
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
                                        bits.add(d.unit.isEmpty
                                            ? v
                                            : '$v ${d.unit}');
                                      }
                                      if (bits.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
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
                                    // Always shown: the shop wants on-hand visible
                                    // for every product, incl. a zero "out of stock"
                                    // (Plan 011 #8).
                                    const SizedBox(height: 8),
                                    _buildStockRow(context, product, l10n),
                                  ],
                                ),
                              ),
                              // Hidden while selecting. Print, edit and delete are
                              // single-row actions sitting exactly where the finger
                              // lands to tick a box — and one of them is delete.
                              if (!_selectionMode)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Only for serialized SKUs (Plan 012) — the vast
                                    // majority of shops never opt in, and an always-on
                                    // button would just crowd the row.
                                    if (product.isSerialized) ...[
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                              Icons.qr_code_2_rounded,
                                              color: AppTheme.primaryColor,
                                              size: 22),
                                          tooltip: l10n.productUnitsAction,
                                          constraints: const BoxConstraints(
                                              minWidth: 48, minHeight: 48),
                                          onPressed: () => context.push(
                                              '/products/units/${product.id}',
                                              extra: product),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.print_rounded,
                                            color: AppTheme.primaryColor,
                                            size: 22),
                                        tooltip: l10n.printLabelTitle,
                                        constraints: const BoxConstraints(
                                            minWidth: 48, minHeight: 48),
                                        onPressed: () =>
                                            _printLabel(context, product),
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
                                            color: AppTheme.primaryColor,
                                            size: 22),
                                        constraints: const BoxConstraints(
                                            minWidth: 48, minHeight: 48),
                                        onPressed: () {
                                          context.push(
                                              '/products/edit/${product.id}',
                                              extra: product);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.red,
                                            size: 22),
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
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        // Add is hidden while selecting: the two are different jobs, and a round
        // "+" floating over a selection bar is the easiest mis-tap on the screen.
        floatingActionButton: _selectionMode
            ? null
            : FloatingActionButton(
                onPressed: () => context.push('/products/add'),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, size: 32),
              ),
        bottomNavigationBar: _selectionMode ? _selectionBar(l10n) : null,
      ),
    );
  }

  /// App bar for selection mode: a way out, the count, and select-all.
  PreferredSizeWidget _selectionAppBar(AppLocalizations l10n) {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: l10n.cancel,
        onPressed: _exitSelection,
      ),
      title: Text(l10n.selectedCount(_selectedIds.length),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          tooltip: l10n.selectAllAction,
          // Select-all means "everything I can currently see", not the whole
          // catalogue: the owner filtered for a reason, and a button that
          // quietly reached past the filter would make bulk editing unsafe.
          onPressed: () {
            final visible = context
                .read<ProductBloc>()
                .state
                .products
                .where(_matchesFilters)
                .map((p) => p.id);
            setState(() => _selectedIds.addAll(visible));
          },
        ),
      ],
    );
  }

  /// The action bar. It sits above the tab bar and reports what the selection
  /// really is before offering to change it.
  Widget _selectionBar(AppLocalizations l10n) {
    final products = context.watch<ProductBloc>().state.products;
    final selected =
        products.where((p) => _selectedIds.contains(p.id)).toList();
    // Selected but filtered out of view — see [_toggleSelected].
    final hidden = selected.where((p) => !_matchesFilters(p)).length;

    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.selectedCount(selected.length),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (hidden > 0)
                Text(
                  l10n.selectionHiddenByFilter(hidden),
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              const SizedBox(height: 8),
              _selectionActions(selected, l10n),
            ],
          ),
        ),
      ),
    );
  }

  /// The action row. Two buttons today (category, price); a third would go here
  /// rather than into a new mode.
  Widget _selectionActions(List<Product> selected, AppLocalizations l10n) {
    final categoryField = _categoryField(context);
    return Row(
      children: [
        // Only offered once the shop has a category field — otherwise the
        // button would open a sheet with nothing to choose.
        if (categoryField != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: selected.isEmpty
                  ? null
                  : () => _openBulkCategorySheet(categoryField, selected, l10n),
              icon: const Icon(Icons.category_outlined, size: 18),
              label: Text(l10n.setCategoryAction,
                  overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: FilledButton.icon(
            onPressed: selected.isEmpty
                ? null
                : () => _openBulkPriceDialog(selected, l10n),
            icon: const Icon(Icons.sell_outlined, size: 18),
            label: Text(l10n.bulkEditPricesAction,
                overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }

  /// Pick a category for the selection — an existing one, "no category", or a
  /// brand-new one typed right here.
  ///
  /// Creating from this sheet is deliberate: the moment an owner notices a
  /// missing section is while they are sorting products into sections, and
  /// sending them to Settings to add it would lose the selection they just
  /// built.
  void _openBulkCategorySheet(
      AttributeDefinition field, List<Product> selected, AppLocalizations l10n) {
    final defBloc = context.read<AttributeDefinitionBloc>();
    final productBloc = context.read<ProductBloc>();
    final ids = {..._selectedIds};

    void apply(String value) {
      productBloc.add(BulkSetAttribute(
          productIds: ids, definitionId: field.id, value: value));
      _exitSelection();
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetCtx) {
        var typed = '';
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) => SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 20 + MediaQuery.of(sheetCtx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.chooseCategoryTitle(selected.length),
                      style: Theme.of(sheetCtx).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final option in field.options)
                            ActionChip(
                              label: Text(option),
                              onPressed: () {
                                Navigator.pop(sheetCtx);
                                apply(option);
                              },
                            ),
                          ActionChip(
                            avatar: const Icon(Icons.block, size: 16),
                            label: Text(l10n.categoryClearOption),
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              apply('');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration:
                              InputDecoration(labelText: l10n.newCategoryHint),
                          onChanged: (v) => setSheet(() => typed = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: typed.trim().isEmpty
                            ? null
                            : () {
                                final value = typed.trim();
                                // Add the option to the field first, then
                                // assign — otherwise the products would hold a
                                // value the category chips never show.
                                defBloc.add(SaveDefinition(field.copyWith(
                                    options: addOptionToList(
                                        field.options, value))));
                                Navigator.pop(sheetCtx);
                                apply(value);
                              },
                        child: Text(l10n.bulkApplyAction),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
    final onVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    // A Wrap (not a Row): on a narrow card the badge drops to a second line
    // instead of overflowing — this row shares width with the action buttons.
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                out
                    ? Icons.production_quantity_limits
                    : Icons.inventory_2_outlined,
                size: 16,
                color: alert ? Colors.red : onVariant),
            const SizedBox(width: 4),
            Text(
              l10n.stockCountLabel(formatQty(product.quantity)),
              style: TextStyle(
                fontSize: 13,
                fontWeight: alert ? FontWeight.bold : FontWeight.w500,
                color: alert ? Colors.red : onVariant,
              ),
            ),
          ],
        ),
        if (alert)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    out
                        ? Icons.remove_shopping_cart
                        : Icons.warning_amber_rounded,
                    size: 14,
                    color: Colors.red),
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
    );
  }

  /// Bulk price/cost edit (Plan 015 B2.2) — the first action on the selection.
  ///
  /// Two modes because the owner has two different jobs: "all ten juice
  /// flavours are now 3000" (set) and "everything goes up 10%" (percent).
  /// Set-to needs one currency across the selection; percent does not — see
  /// [mixesCurrencies].
  void _openBulkPriceDialog(List<Product> selected, AppLocalizations l10n) {
    final mixed = mixesCurrencies(selected);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        var field = BulkPriceField.price;
        // A mixed-currency selection can only be edited by percentage, so start
        // there rather than opening on a mode that is already blocked.
        var mode = mixed ? BulkPriceMode.percent : BulkPriceMode.setTo;
        var increase = true;
        // A plain string, not a TextEditingController: nothing here writes the
        // field programmatically, and a controller made in a dialog builder has
        // no dispose to hang it on.
        var typed = '';

        return StatefulBuilder(
          builder: (dialogCtx, setDialog) {
            final entered = NumInput.parseFlexibleNumber(typed);
            final signed = entered == null
                ? null
                : (mode == BulkPriceMode.percent && !increase
                    ? -entered
                    : entered);
            final edit = signed == null
                ? null
                : BulkPriceEdit(field: field, mode: mode, value: signed);
            final affected =
                edit == null ? 0 : selected.where(edit.changes).length;

            return AlertDialog(
              title: Text(l10n.bulkPriceTitle(selected.length)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<BulkPriceField>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                            value: BulkPriceField.price,
                            label: Text(l10n.bulkFieldPrice)),
                        ButtonSegment(
                            value: BulkPriceField.cost,
                            label: Text(l10n.bulkFieldCost)),
                      ],
                      selected: {field},
                      onSelectionChanged: (s) =>
                          setDialog(() => field = s.first),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<BulkPriceMode>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: BulkPriceMode.setTo,
                          label: Text(l10n.bulkModeSetTo),
                          enabled: !mixed,
                        ),
                        ButtonSegment(
                            value: BulkPriceMode.percent,
                            label: Text(l10n.bulkModePercent)),
                      ],
                      selected: {mode},
                      onSelectionChanged: (s) =>
                          setDialog(() => mode = s.first),
                    ),
                    if (mixed) ...[
                      const SizedBox(height: 8),
                      Text(l10n.bulkMixedCurrency,
                          style: TextStyle(
                              fontSize: 12, color: Colors.orange.shade800)),
                    ],
                    if (mode == BulkPriceMode.percent) ...[
                      const SizedBox(height: 12),
                      // An up/down toggle instead of a typed minus: the numeric
                      // keypad these shops use has no comfortable '-', and
                      // NumInput.decimalFormatters block it anyway.
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                              value: true,
                              icon: const Icon(Icons.arrow_upward, size: 16),
                              label: Text(l10n.bulkPercentIncrease)),
                          ButtonSegment(
                              value: false,
                              icon: const Icon(Icons.arrow_downward, size: 16),
                              label: Text(l10n.bulkPercentDecrease)),
                        ],
                        selected: {increase},
                        onSelectionChanged: (s) =>
                            setDialog(() => increase = s.first),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: true,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: NumInput.decimalFormatters,
                      decoration: InputDecoration(
                        labelText: mode == BulkPriceMode.percent
                            ? l10n.bulkPercentLabel
                            : l10n.bulkAmountLabel,
                      ),
                      onChanged: (v) => setDialog(() => typed = v),
                    ),
                    const SizedBox(height: 12),
                    // The preview is the safety net: it is the only place the
                    // owner learns that "10%" would move 3 rows, not the 12
                    // they ticked.
                    Text(
                      affected == 0
                          ? l10n.bulkPreviewNoChange
                          : l10n.bulkPreviewCount(affected),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: affected == 0
                            ? Theme.of(dialogCtx).colorScheme.onSurfaceVariant
                            : AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: affected == 0
                      ? null
                      : () {
                          Navigator.pop(dialogCtx);
                          context.read<ProductBloc>().add(BulkUpdatePrices(
                                productIds: {..._selectedIds},
                                edit: edit!,
                              ));
                          _exitSelection();
                        },
                  child: Text(l10n.bulkApplyAction),
                ),
              ],
            );
          },
        );
      },
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
              child:
                  Text(l10n.delete, style: const TextStyle(color: Colors.red)),
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
                          color: Theme.of(dialogCtx)
                              .colorScheme
                              .onSurfaceVariant)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(l10n.labelCopies),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed:
                            copies > 1 ? () => setDialog(() => copies--) : null,
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
