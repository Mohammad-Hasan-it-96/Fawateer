import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

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

class AddProductPage extends StatefulWidget {
  /// Pre-fills the barcode field. Set when the user scans an unknown barcode at
  /// the POS and chooses to create the product from it, so they don't have to
  /// read the digits off the screen and retype them.
  final String? initialBarcode;

  const AddProductPage({super.key, this.initialBarcode});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _barcode = '';
  double _price = 0.0;
  double _cost = 0.0;
  double _quantity = 0.0;
  double _minStockAlert = 0.0;
  bool _isSerialized = false;
  ProductSaleType _saleType = ProductSaleType.piece;
  PriceCurrency _priceCurrency = PriceCurrency.sp;
  Map<String, String> _attributes = {};

  @override
  void initState() {
    super.initState();
    _barcode = widget.initialBarcode ?? '';
  }

  void _scanBarcode() async {
    final result = await context.push<String>('/scanner');
    if (result != null && result.isNotEmpty) {
      setState(() {
        _barcode = result;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final productState = context.read<ProductBloc>().state;
      final l10n = AppLocalizations.of(context)!;

      // Only non-empty barcodes must be unique; many items legitimately have no
      // barcode (loose produce, bakery), so blank barcodes are always allowed.
      final isDuplicate = _barcode.isNotEmpty &&
          productState.products.any((p) => p.barcode == _barcode);

      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.barcodeExistsError),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Product names must be unique (case-insensitive) so a misread barcode
      // can't spawn a second "same" product the cashier then can't tell apart.
      final nameExists = productState.products.any(
          (p) => p.name.trim().toLowerCase() == _name.trim().toLowerCase());
      if (nameExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productNameExistsError),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final product = Product(
        id: const Uuid().v4(),
        name: _name,
        barcode: _barcode,
        price: _price,
        cost: _cost,
        quantity: _quantity,
        isSerialized: _isSerialized,
        minStockAlert: _minStockAlert,
        saleType: _saleType,
        priceCurrency: _priceCurrency,
        attributes: ProductAttributes(_attributes),
      );

      context.read<ProductBloc>().add(AddProduct(product));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 28, color: Theme.of(context).primaryColor),
            onPressed: () => context.pop(),
          ),
          title: Text(l10n.addProductTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InputLabel(text: l10n.productNameLabel),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: l10n.productNameHint,
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: AppValidators.required(l10n.fieldRequired),
                    onSaved: (value) => _name = value!.trim(),
                  ),
                  const SizedBox(height: 24),
                  InputLabel(text: l10n.barcodeLabel),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey(_barcode),
                          initialValue: _barcode,
                          decoration: InputDecoration(
                            hintText: l10n.scanOrEnterBarcode,
                          ),
                          // Barcode is optional: loose produce/bakery items have
                          // none. Only non-empty barcodes must be unique.
                          onSaved: (value) => _barcode = value ?? '',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.qr_code_scanner,
                              color: AppTheme.primaryColor),
                          onPressed: _scanBarcode,
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(l10n.tapToScan,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
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
                    // Start empty (Plan 011 #3): a pre-filled '0' reads as a
                    // filled field and confuses first-time entry. onSaved still
                    // coalesces blank → 0.
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
                  InputLabel(text: l10n.stockLabel),
                  TextFormField(
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: NumInput.decimalFormatters,
                    decoration: InputDecoration(
                      hintText: '0',
                      helperText: l10n.stockHint,
                    ),
                    // Empty by default (Plan 011 #3); hint shows '0'.
                    validator: AppValidators.optionalNonNegative(
                      invalidMsg: l10n.invalidNumber,
                      negativeMsg: l10n.negativeNotAllowed,
                    ),
                    onSaved: (value) {
                      // A serialized SKU starts at 0 and counts up as units are
                      // added (Plan 012 D1) — typing a quantity here would be
                      // immediately overwritten, so ignore it.
                      if (_isSerialized) return;
                      _quantity = NumInput.parseFlexibleNumber(value) ?? 0;
                    },
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _isSerialized,
                    onChanged: (v) => setState(() => _isSerialized = v),
                    title: Text(l10n.productSerialized),
                    subtitle: Text(l10n.productSerializedHint),
                  ),
                  const SizedBox(height: 24),
                  InputLabel(text: l10n.lowStockAlertLabel),
                  TextFormField(
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: NumInput.decimalFormatters,
                    decoration: InputDecoration(
                      hintText: '0',
                      helperText: l10n.lowStockAlertHint,
                    ),
                    // Empty by default (Plan 011 #3); hint shows '0'.
                    validator: AppValidators.optionalNonNegative(
                      invalidMsg: l10n.invalidNumber,
                      negativeMsg: l10n.negativeNotAllowed,
                    ),
                    onSaved: (value) =>
                        _minStockAlert = NumInput.parseFlexibleNumber(value) ?? 0,
                  ),
                  // Owner-defined custom fields (Plan 010) — rendered from the
                  // active definitions; empty for shops that defined none.
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
          icon: Icons.add_circle,
          label: l10n.addProductBtn,
        ));
  }
}
