import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/product_bloc.dart';
import '../widgets/currency_field.dart';
import '../widgets/price_currency_selector.dart';
import '../widgets/sale_type_selector.dart';
import '../../domain/entities/price_currency.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_sale_type.dart';
import '../../../attributes/presentation/bloc/attribute_definition_bloc.dart';
import '../../../attributes/presentation/widgets/attribute_form_fields.dart';
import '../../../../core/attributes/product_attributes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../core/utils/num_input.dart';
import '../../../../l10n/app_localizations.dart';

/// Show a whole-number quantity as `5`, not `5.0`.
String _formatQty(double q) =>
    q == q.truncateToDouble() ? q.toInt().toString() : q.toString();

class EditProductPage extends StatefulWidget {
  final Product product;
  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late double _price;
  late double _cost;
  late double _quantity;
  late bool _isSerialized;
  late double _minStockAlert;
  late ProductSaleType _saleType;
  late PriceCurrency _priceCurrency;
  late Map<String, String> _attributes;

  @override
  void initState() {
    super.initState();
    _name = widget.product.name;
    _price = widget.product.price;
    _cost = widget.product.cost;
    _quantity = widget.product.quantity;
    _isSerialized = widget.product.isSerialized;
    _minStockAlert = widget.product.minStockAlert;
    _saleType = widget.product.saleType;
    _priceCurrency = widget.product.priceCurrency;
    _attributes = Map<String, String>.from(widget.product.attributes.values);
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Product names must stay unique (case-insensitive), excluding this same
      // product — so renaming can't collide with another existing product.
      final products = context.read<ProductBloc>().state.products;
      final nameExists = products.any((p) =>
          p.id != widget.product.id &&
          p.name.trim().toLowerCase() == _name.trim().toLowerCase());
      if (nameExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.productNameExistsError),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // copyWith so fields not on this form (id, barcode, …) are preserved.
      final updatedProduct = widget.product.copyWith(
        name: _name,
        price: _price,
        cost: _cost,
        quantity: _quantity,
        isSerialized: _isSerialized,
        minStockAlert: _minStockAlert,
        saleType: _saleType,
        priceCurrency: _priceCurrency,
        attributes: ProductAttributes(_attributes),
      );

      context.read<ProductBloc>().add(UpdateProduct(updatedProduct));
      context.pop();
    }
  }

  /// Opt-in per-unit identity (Plan 012). Deliberately a switch on the normal
  /// product form rather than a separate mode: for a phone shop this is one
  /// setting on the product they were already creating.
  Widget _serializedToggle(AppLocalizations l10n) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _isSerialized,
        onChanged: (v) => setState(() => _isSerialized = v),
        title: Text(l10n.productSerialized),
        subtitle: Text(l10n.productSerializedHint),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 32, color: Theme.of(context).primaryColor),
            onPressed: () => context.pop(),
          ),
          title: Text(l10n.editProductTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_scanner,
                            color: AppTheme.primaryColor, size: 28),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.barcodeDisplay,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.7))),
                            const SizedBox(height: 2),
                            Text(widget.product.barcode,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  InputLabel(text: l10n.productNameLabel),
                  TextFormField(
                    initialValue: _name,
                    textCapitalization: TextCapitalization.words,
                    validator: AppValidators.required(l10n.fieldRequired),
                    onSaved: (value) => _name = value!.trim(),
                  ),
                  const SizedBox(height: 24),

                  InputLabel(text: l10n.saleTypeLabel),
                  SaleTypeSelector(
                    value: _saleType,
                    onChanged: (t) => setState(() => _saleType = t),
                  ),
                  const SizedBox(height: 24),

                  InputLabel(text: l10n.priceCurrencyLabel),
                  PriceCurrencySelector(
                    value: _priceCurrency,
                    onChanged: (c) => setState(() => _priceCurrency = c),
                  ),
                  const SizedBox(height: 24),

                  InputLabel(
                      text: _saleType.isMeasured
                          ? l10n.pricePerKgLabel
                          : l10n.priceLabel),
                  CurrencyField(
                    initialValue: _price.toStringAsFixed(2),
                    currencySymbol:
                        _priceCurrency == PriceCurrency.usd ? '\$' : null,
                    validator: AppValidators.price(
                      requiredMsg: l10n.fieldRequired,
                      invalidMsg: l10n.invalidPrice,
                      negativeMsg: l10n.negativePriceError,
                      mustBePositiveMsg: l10n.priceMustBePositive,
                    ),
                    onSaved: (value) =>
                        _price = NumInput.parseFlexibleNumber(value) ?? 0,
                  ),
                  const SizedBox(height: 24),

                  InputLabel(text: l10n.costLabel),
                  CurrencyField(
                    initialValue: _cost.toStringAsFixed(2),
                    currencySymbol:
                        _priceCurrency == PriceCurrency.usd ? '\$' : null,
                    helperText: l10n.costHint,
                    validator: AppValidators.optionalNonNegative(
                      invalidMsg: l10n.invalidNumber,
                      negativeMsg: l10n.negativeNotAllowed,
                    ),
                    onSaved: (value) =>
                        _cost = NumInput.parseFlexibleNumber(value) ?? 0,
                  ),
                  const SizedBox(height: 24),

                  InputLabel(text: l10n.stockEditLabel),
                  TextFormField(
                    // Read-only once the SKU is serialized (Plan 012 D1): stock
                    // is then a cache of the unit count, and letting this field
                    // save over it would silently break the invariant the whole
                    // feature rests on. The number still shows, so the owner
                    // can see it — they just change it by adding units.
                    key: ValueKey('qty-$_isSerialized'),
                    initialValue: _formatQty(_quantity),
                    readOnly: _isSerialized,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: NumInput.decimalFormatters,
                    decoration: InputDecoration(
                      helperText: _isSerialized
                          ? l10n.stockFromUnitsHint
                          : l10n.stockEditHint,
                    ),
                    validator: AppValidators.optionalNonNegative(
                      invalidMsg: l10n.invalidNumber,
                      negativeMsg: l10n.negativeNotAllowed,
                    ),
                    onSaved: (value) {
                      if (_isSerialized) return; // units are the source of truth
                      _quantity = NumInput.parseFlexibleNumber(value) ?? 0;
                    },
                  ),
                  const SizedBox(height: 24),

                  _serializedToggle(l10n),
                  const SizedBox(height: 24),

                  InputLabel(text: l10n.lowStockAlertLabel),
                  TextFormField(
                    initialValue: _formatQty(_minStockAlert),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: NumInput.decimalFormatters,
                    decoration: InputDecoration(
                      hintText: '0',
                      helperText: l10n.lowStockAlertHint,
                    ),
                    validator: AppValidators.optionalNonNegative(
                      invalidMsg: l10n.invalidNumber,
                      negativeMsg: l10n.negativeNotAllowed,
                    ),
                    onSaved: (value) =>
                        _minStockAlert = NumInput.parseFlexibleNumber(value) ?? 0,
                  ),
                  // Owner-defined custom fields (Plan 010).
                  Builder(builder: (context) {
                    final defs = context
                        .watch<AttributeDefinitionBloc>()
                        .state
                        .active;
                    return AttributeFormFields(
                      definitions: defs,
                      initialValues: _attributes,
                      onChanged: (v) => _attributes = v,
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: PrimaryButton(
          onPressed: _submit,
          icon: Icons.save,
          label: l10n.saveChangesBtn,
        ));
  }
}
