import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/product_sale_type.dart';

/// Segmented selector for a product's [ProductSaleType]. A segmented control
/// (rather than a switch) so future measured types (volume, length, box…) just
/// become extra segments.
class SaleTypeSelector extends StatelessWidget {
  final ProductSaleType value;
  final ValueChanged<ProductSaleType> onChanged;

  const SaleTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ProductSaleType>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: ProductSaleType.piece,
            label: Text(l10n.saleTypePiece),
            icon: const Icon(Icons.numbers, size: 18),
          ),
          ButtonSegment(
            value: ProductSaleType.weight,
            label: Text(l10n.saleTypeWeight),
            icon: const Icon(Icons.scale, size: 18),
          ),
        ],
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}
