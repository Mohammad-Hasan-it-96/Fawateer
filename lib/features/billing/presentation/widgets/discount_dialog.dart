import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/num_input.dart';
import '../../../../l10n/app_localizations.dart';

/// Ask the cashier for a manual discount on [base] (a line subtotal or the cart
/// subtotal, in SP). Returns the **resolved SP discount** (0 = removed), or null
/// if cancelled. The cashier picks percent or a fixed amount; the result is
/// rounded to whole SP and clamped to [base] so a total can never go negative.
Future<double?> showDiscountDialog({
  required BuildContext context,
  required double base,
  required String currency,
  double initialDiscount = 0,
}) {
  return showDialog<double>(
    context: context,
    builder: (_) => _DiscountDialog(
      base: base,
      currency: currency,
      initialDiscount: initialDiscount,
    ),
  );
}

class _DiscountDialog extends StatefulWidget {
  final double base;
  final String currency;
  final double initialDiscount;

  const _DiscountDialog({
    required this.base,
    required this.currency,
    required this.initialDiscount,
  });

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

enum _Mode { percent, amount }

class _DiscountDialogState extends State<_DiscountDialog> {
  _Mode _mode = _Mode.amount;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDiscount;
    _controller = TextEditingController(text: d > 0 ? _trim(d) : '');
  }

  String _trim(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The resolved SP discount for the current input, clamped to [0, base].
  double get _resolved {
    final v = NumInput.parseFlexibleNumber(_controller.text) ?? 0;
    if (v <= 0) return 0;
    final raw = _mode == _Mode.percent ? widget.base * v / 100 : v;
    final rounded = raw.roundToDouble();
    return rounded > widget.base ? widget.base : rounded;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final discount = _resolved;
    final net = widget.base - discount;

    return AlertDialog(
      title: Text(l10n.discountTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<_Mode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                  value: _Mode.percent,
                  label: Text(l10n.discountPercent),
                  icon: const Icon(Icons.percent, size: 16)),
              ButtonSegment(
                  value: _Mode.amount,
                  label: Text(l10n.discountAmount),
                  icon: const Icon(Icons.attach_money, size: 16)),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: NumInput.decimalFormatters,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.discountValueHint,
              suffixText: _mode == _Mode.percent ? '%' : widget.currency,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.discountTitle,
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text('- ${widget.currency}${discount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.colTotal,
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text('${widget.currency}${net.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor)),
            ],
          ),
        ],
      ),
      actions: [
        if (widget.initialDiscount > 0)
          TextButton(
            onPressed: () => Navigator.of(context).pop(0.0),
            child: Text(l10n.discountRemove,
                style: const TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_resolved),
          child: Text(l10n.discountApply),
        ),
      ],
    );
  }
}
