import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/license_bloc.dart';
import '../licensing_error_text.dart';

/// Gate screen for a subscription blocked by a *guard*, not by the
/// subscription itself: too long offline ([LicenseGuards.offlineGrace]) or a
/// rolled-back device clock. Both clear on one successful server check, so
/// this screen explains the situation honestly and offers a Retry — unlike
/// the plans page, which would read as "pay again" to a paying shop.
///
/// Adapted from the Smart-Agent reference app's OfflineLimitScreen.
class VerificationRequiredPage extends StatelessWidget {
  const VerificationRequiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<LicenseBloc, LicenseState>(
          listenWhen: (p, c) => c.error != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(licenseErrorText(state.error!, l10n)),
              backgroundColor: Colors.red,
            ));
          },
          builder: (context, state) {
            final lic = state.license;
            final tampered = lic.timeTampered;
            final checking = state.status == LicenseFlowStatus.checking;
            final color =
                tampered ? Colors.red.shade600 : Colors.orange.shade800;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                          tampered ? Icons.history_toggle_off : Icons.wifi_off,
                          size: 48,
                          color: color),
                    ),
                    const SizedBox(height: 20),
                    Text(l10n.verifyRequiredTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(
                      tampered
                          ? l10n.verifyTamperMessage
                          : l10n.verifyOfflineMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    // The shop's data is untouched — say so, same reassurance
                    // as the expired-plans notice.
                    Text(
                      l10n.verifyDataSafe,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor),
                        onPressed: checking
                            ? null
                            : () => context
                                .read<LicenseBloc>()
                                .add(CheckLicenseEvent()),
                        icon: checking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.refresh),
                        label: Text(
                            checking ? l10n.verifyChecking : l10n.retry,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
