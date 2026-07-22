import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/price_currency.dart';

/// Segmented selector for a product's [PriceCurrency] (SP base vs USD sticker).
/// A segmented control (like [SaleTypeSelector]) so future currencies just
/// become extra segments.
class PriceCurrencySelector extends StatelessWidget {
  final PriceCurrency value;
  final ValueChanged<PriceCurrency> onChanged;

  const PriceCurrencySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<PriceCurrency>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: PriceCurrency.sp,
            label: Text(l10n.currencySp),
            icon: const Icon(Icons.currency_pound, size: 18),
          ),
          ButtonSegment(
            value: PriceCurrency.usd,
            label: Text(l10n.currencyUsd),
            icon: const Icon(Icons.attach_money, size: 18),
          ),
        ],
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}
