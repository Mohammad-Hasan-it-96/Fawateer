import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/license_bloc.dart';
import '../licensing_error_text.dart';
import '../widgets/device_id_card.dart';

/// Gate screen for an unlicensed / expired device. Captures the agent's name +
/// phone, lets them (re-)send an activation request, and routes to the plan
/// catalogue for a purchase.
class ActivationPage extends StatefulWidget {
  const ActivationPage({super.key});

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final s = context.read<LicenseBloc>().state;
    _name = TextEditingController(text: s.agentName);
    _phone = TextEditingController(text: s.agentPhone);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _activate() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<LicenseBloc>().add(ActivateLicenseEvent(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: BlocConsumer<LicenseBloc, LicenseState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(licenseErrorText(state.error!, l10n)),
                backgroundColor: Colors.red,
              ));
            }
          },
          builder: (context, state) {
            final busy = state.status == LicenseFlowStatus.activating;
            final expired = state.license.expiresAt != null &&
                state.license.isExpired;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      Icon(expired ? Icons.lock_clock : Icons.workspace_premium,
                          size: 64, color: AppTheme.primaryColor),
                      const SizedBox(height: 16),
                      Text(
                        expired ? l10n.licenseExpiredTitle : l10n.activationTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        expired
                            ? l10n.licenseExpiredSubtitle
                            : l10n.activationSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      if (state.license.expiresAt != null) ...[
                        const SizedBox(height: 12),
                        _expiryChip(l10n, state.license.expiresAt!, expired),
                      ],
                      const SizedBox(height: 32),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _name,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: l10n.activationNameLabel,
                                prefixIcon: const Icon(Icons.person_outline),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? l10n.fieldRequired
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: l10n.activationPhoneLabel,
                                prefixIcon: const Icon(Icons.phone_outlined),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? l10n.fieldRequired
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: busy ? null : _activate,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(l10n.activationCheckButton),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed:
                            busy ? null : () => context.push('/activation/plans'),
                        icon: const Icon(Icons.list_alt),
                        label: Text(l10n.activationViewPlans),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      DeviceIdCard(deviceId: state.deviceId, l10n: l10n),
                    ],
                  ),
                ),
                if (busy)
                  const ColoredBox(
                    color: Color(0x66000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _expiryChip(AppLocalizations l10n, DateTime expiresAt, bool expired) {
    final formatted = DateFormat.yMMMd('ar').format(expiresAt);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (expired ? Colors.red : Colors.teal).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        l10n.licenseExpiresOn(formatted),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: expired ? Colors.red[700] : Colors.teal[700],
        ),
      ),
    );
  }
}
