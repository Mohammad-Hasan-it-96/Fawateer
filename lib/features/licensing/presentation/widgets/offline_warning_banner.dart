import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/guards/license_guards.dart';
import '../bloc/license_bloc.dart';

/// Soft "connect to the internet soon" strip, shown while the app is still
/// **unlocked** but hasn't reached the server for more than
/// [LicenseGuards.offlineWarnAfter] (3 days). The hard lock only comes at
/// [LicenseGuards.offlineGrace] (7 days) — this banner is the fair warning in
/// between, so the lock never feels like it came out of nowhere. Tapping it
/// retries the server check on the spot.
///
/// Renders nothing when recently synced (the overwhelmingly common case).
class OfflineWarningBanner extends StatelessWidget {
  const OfflineWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<LicenseBloc, LicenseState>(
      builder: (context, state) {
        final lic = state.license;
        final now = DateTime.now();
        if (!lic.isActive ||
            !LicenseGuards.isOfflineWarning(lic.lastServerSync, now)) {
          return const SizedBox.shrink();
        }
        final days = LicenseGuards.daysOffline(lic.lastServerSync, now) ?? 0;
        final checking = state.status == LicenseFlowStatus.checking;

        return Material(
          color: Colors.amber.shade800,
          child: InkWell(
            onTap: checking
                ? null
                : () => context.read<LicenseBloc>().add(CheckLicenseEvent()),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.offlineWarnBanner(days),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (checking)
                      const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                    else
                      Text(
                        l10n.retry,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
