import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/currency/exchange_rate_service.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/num_input.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../billing/presentation/bloc/billing_bloc.dart';

/// Quick modal to set the USD→SP exchange rate — reachable from the POS chip and
/// Settings → Currency. Prefills from the live [BillingBloc] state, saves via
/// [ExchangeRateService], then re-prices the cart. SP is the base currency; this
/// rate only affects **future** sales (past invoices snapshot their own rate).
Future<void> showExchangeRateSheet(BuildContext context) {
  final billing = context.read<BillingBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => BlocProvider<BillingBloc>.value(
      value: billing,
      child: const _ExchangeRateSheet(),
    ),
  );
}

class _ExchangeRateSheet extends StatefulWidget {
  const _ExchangeRateSheet();

  @override
  State<_ExchangeRateSheet> createState() => _ExchangeRateSheetState();
}

class _ExchangeRateSheetState extends State<_ExchangeRateSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final rate = context.read<BillingBloc>().state.exchangeRate;
    _controller = TextEditingController(text: rate == null ? '' : _trim(rate));
  }

  String _trim(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final rate = NumInput.parseFlexibleNumber(_controller.text);
    if (rate == null || rate <= 0) return;

    setState(() => _saving = true);
    await sl<ExchangeRateService>().setRate(rate);
    if (!mounted) return;
    context.read<BillingBloc>().add(const LoadExchangeRateEvent());

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(
      content: Text(l10n.exchangeRateSaved),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final updatedAt = context.read<BillingBloc>().state.rateUpdatedAt;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.currency_exchange,
                    color: AppTheme.primaryColor),
                const SizedBox(width: 10),
                Text(l10n.currencySettingsTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(l10n.currencySettingsNote,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 20),
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: NumInput.decimalFormatters,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: l10n.exchangeRateLabel,
                hintText: l10n.exchangeRateHint,
                prefixIcon: const Icon(Icons.attach_money),
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final n = NumInput.parseFlexibleNumber(v);
                if (n == null || n <= 0) return l10n.exchangeRateInvalid;
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              updatedAt == null
                  ? l10n.exchangeRateNever
                  : l10n.exchangeRateUpdatedAt(
                      DateFormat.yMMMd().add_jm().format(updatedAt)),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(l10n.save,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
