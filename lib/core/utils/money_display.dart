import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/shop/presentation/bloc/shop_bloc.dart';

/// The shop's currency symbol (from the app-wide [ShopBloc]), or '' if not
/// loaded yet.
String currencyOf(BuildContext context) {
  final state = context.read<ShopBloc>().state;
  return state is ShopLoaded ? state.shop.currencySymbol : '';
}

/// Format an amount with the shop currency (absolute value; callers convey sign
/// via colour/label). Money stays `double`, shown at 2 decimals.
String moneyText(BuildContext context, double amount) {
  final symbol = currencyOf(context);
  final n = amount.abs().toStringAsFixed(2);
  return symbol.isEmpty ? n : '$n $symbol';
}
