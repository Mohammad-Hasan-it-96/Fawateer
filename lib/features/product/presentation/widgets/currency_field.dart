import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../../core/utils/num_input.dart';

/// A money input that prefixes the shop's currency symbol. Centralizes the
/// price/cost fields that were duplicated across the add/edit product forms.
class CurrencyField extends StatelessWidget {
  final String? initialValue;
  final String hintText;
  final String? helperText;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;

  /// When set, overrides the shop's currency symbol as the field prefix — used
  /// to show `$` on a USD-priced product instead of the SP base symbol.
  final String? currencySymbol;

  const CurrencyField({
    super.key,
    this.initialValue,
    this.hintText = '0.00',
    this.helperText,
    this.validator,
    this.onSaved,
    this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final shopState = context.watch<ShopBloc>().state;
    final currency = currencySymbol ??
        (shopState is ShopLoaded ? shopState.shop.currencySymbol : '');
    return TextFormField(
      initialValue: initialValue,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: NumInput.decimalFormatters,
      decoration: InputDecoration(
        hintText: hintText,
        helperText: helperText,
        prefixText: currency.isNotEmpty ? '$currency ' : null,
        prefixStyle: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }
}
