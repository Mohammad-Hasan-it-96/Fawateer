import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/currency/exchange_rate_service.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/num_input.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../billing/presentation/bloc/billing_bloc.dart';

/// Settings → Currency: set the single USD→SP exchange rate used to price
/// USD-stickered products into SP at sale time. SP is the base/book currency;
/// this rate only affects **future** sales (past invoices snapshot their own
/// rate). See `docs/plans/003-dual-currency.md`.
class CurrencySettingsPage extends StatefulWidget {
  const CurrencySettingsPage({super.key});

  @override
  State<CurrencySettingsPage> createState() => _CurrencySettingsPageState();
}

class _CurrencySettingsPageState extends State<CurrencySettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final ExchangeRateService _service = sl<ExchangeRateService>();

  DateTime? _updatedAt;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rate = await _service.getRate();
    final updatedAt = await _service.getUpdatedAt();
    if (!mounted) return;
    setState(() {
      if (rate != null) _controller.text = _trim(rate);
      _updatedAt = updatedAt;
      _loading = false;
    });
  }

  /// Show 15000 not 15000.0, but keep decimals if the owner entered them.
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
    await _service.setRate(rate);
    if (!mounted) return;
    // Re-price any USD lines currently in the cart with the new rate.
    context.read<BillingBloc>().add(const LoadExchangeRateEvent());
    setState(() {
      _saving = false;
      _updatedAt = DateTime.now();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n.exchangeRateSaved),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(l10n.currencySettingsTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: AppTheme.primaryColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(l10n.currencySettingsNote,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[700])),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(l10n.exchangeRateLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _controller,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: NumInput.decimalFormatters,
                        decoration: InputDecoration(
                          hintText: l10n.exchangeRateHint,
                          prefixIcon: const Icon(Icons.currency_exchange),
                        ),
                        validator: (v) {
                          final n = NumInput.parseFlexibleNumber(v);
                          if (n == null || n <= 0) {
                            return l10n.exchangeRateInvalid;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _updatedAt == null
                            ? l10n.exchangeRateNever
                            : l10n.exchangeRateUpdatedAt(
                                DateFormat.yMMMd().add_jm().format(_updatedAt!)),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 28),
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
              ),
            ),
    );
  }
}
