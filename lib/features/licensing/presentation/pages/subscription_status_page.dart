import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/license_bloc.dart';
import '../licensing_error_text.dart';
import '../widgets/device_id_card.dart';

/// Subscription status & management for an already-activated device. Reachable
/// from Settings (the gate only redirects unlicensed users, so this is only hit
/// while active). Lets the user re-check with the server and renew/change plan.
class SubscriptionStatusPage extends StatelessWidget {
  const SubscriptionStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.subscriptionTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: BlocConsumer<LicenseBloc, LicenseState>(
        listenWhen: (p, c) => c.error != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(licenseErrorText(state.error!, l10n)),
            backgroundColor: Colors.red,
          ));
        },
        builder: (context, state) {
          final license = state.license;
          final checking = state.status == LicenseFlowStatus.checking;

          final expired = license.isExpired;
          final (statusLabel, statusColor, statusIcon) = _status(l10n, state);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Status card ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                ),
                child: Column(
                  children: [
                    Icon(statusIcon, size: 52, color: statusColor),
                    const SizedBox(height: 10),
                    Text(statusLabel,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: statusColor)),
                    if (license.planName != null &&
                        license.planName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(license.planName!,
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Details ─────────────────────────────────────────────────
              if (license.expiresAt != null)
                _detailRow(
                  Icons.event_available,
                  l10n.licenseExpiresOn(_fmt(license.expiresAt!)),
                  trailing: license.daysRemaining != null && !expired
                      ? _chip(l10n.daysRemaining(license.daysRemaining!),
                          statusColor)
                      : null,
                ),
              _detailRow(
                Icons.sync,
                license.lastServerSync == null
                    ? l10n.lastChecked(l10n.neverChecked)
                    : l10n.lastChecked(_fmt(license.lastServerSync!)),
              ),
              const SizedBox(height: 24),

              // ── Actions ─────────────────────────────────────────────────
              OutlinedButton.icon(
                onPressed: checking
                    ? null
                    : () =>
                        context.read<LicenseBloc>().add(CheckLicenseEvent()),
                icon: checking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
                label: Text(l10n.refreshStatus),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () =>
                    context.push('/settings/subscription/plans'),
                icon: const Icon(Icons.workspace_premium),
                label: Text(l10n.renewSubscription),
                style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
              const SizedBox(height: 24),
              DeviceIdCard(deviceId: state.deviceId, l10n: l10n),
            ],
          );
        },
      ),
    );
  }

  (String, Color, IconData) _status(AppLocalizations l10n, LicenseState state) {
    final license = state.license;
    if (license.isExpired) {
      return (l10n.statusExpired, Colors.red.shade600, Icons.lock_clock);
    }
    if (license.isTrial) {
      return (l10n.statusTrial, Colors.orange.shade700, Icons.hourglass_bottom);
    }
    if (license.isActive) {
      return (l10n.statusActive, Colors.green.shade600, Icons.verified);
    }
    return (l10n.statusInactive, Colors.grey, Icons.help_outline);
  }

  String _fmt(DateTime d) => DateFormat.yMMMd('ar').format(d);

  Widget _detailRow(IconData icon, String text, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      );
}
