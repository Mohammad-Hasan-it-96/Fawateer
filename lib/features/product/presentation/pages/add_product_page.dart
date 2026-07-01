import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../bloc/product_bloc.dart';
import '../widgets/currency_field.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../l10n/app_localizations.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

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
      // Only non-empty barcodes must be unique; many items legitimately have no
      // barcode (loose produce, bakery), so blank barcodes are always allowed.
      final isDuplicate = _barcode.isNotEmpty &&
          productState.products.any((p) => p.barcode == _barcode);

      if (isDuplicate) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.barcodeExistsError),
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
        minStockAlert: _minStockAlert,
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
                    onSaved: (value) => _name = value!,
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
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF4C669A))),
                  const SizedBox(height: 24),
                  InputLabel(text: l10n.priceLabel),
                  CurrencyField(
                    validator: AppValidators.price,
                    onSaved: (value) => _price = double.parse(value!),
                  ),
                  const SizedBox(height: 24),
                  InputLabel(text: l10n.costLabel),
                  CurrencyField(
                    initialValue: '0',
                    helperText: l10n.costHint,
                    onSaved: (value) =>
                        _cost = double.tryParse(value ?? '0') ?? 0,
                  ),
                  const SizedBox(height: 24),
                  InputLabel(text: l10n.stockLabel),
                  TextFormField(
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: '0',
                      helperText: l10n.stockHint,
                    ),
                    initialValue: '0',
                    onSaved: (value) =>
                        _quantity = double.tryParse(value ?? '0') ?? 0,
                  ),
                  const SizedBox(height: 24),
                  InputLabel(text: l10n.lowStockAlertLabel),
                  TextFormField(
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: '0',
                      helperText: l10n.lowStockAlertHint,
                    ),
                    initialValue: '0',
                    onSaved: (value) =>
                        _minStockAlert = double.tryParse(value ?? '0') ?? 0,
                  ),
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
