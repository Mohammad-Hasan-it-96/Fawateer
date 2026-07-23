import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../bloc/license_bloc.dart';

/// Slim, non-blocking banner shown across the whole app **only while a free
/// trial is active** (`isTrial && isActive`). Displays the days left and taps
/// through to the plans page to upgrade. Turns red in the final stretch to
/// nudge conversion. Renders nothing for paid/expired/unlicensed states, so it
/// costs zero space outside a trial.
class TrialBanner extends StatelessWidget {
  const TrialBanner({super.key});

  static const _urgentThreshold = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<LicenseBloc, LicenseState>(
      buildWhen: (p, c) => p.license != c.license,
      builder: (context, state) {
        final lic = state.license;
        if (!(lic.isTrial && lic.isActive)) return const SizedBox.shrink();

        // null = the server sent no expiry date at all (e.g. a data problem).
        // That is NOT the same as "0 days left" — 0 must only ever mean
        // "expires today". Unknown renders without a count, and never as
        // urgent-red, so a missing date can't masquerade as an ending trial.
        final days = lic.daysRemaining?.clamp(0, 100000);
        final urgent = days != null && days <= _urgentThreshold;
        final bg = urgent ? Colors.red.shade600 : Colors.orange.shade800;

        return Material(
          color: bg,
          child: InkWell(
            onTap: () => context.push('/settings/subscription/plans'),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_bottom,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        // Mirror the subscription display: show the end *date*
                        // alongside the countdown, so "when does my trial end?"
                        // is answered without opening the subscription page.
                        days == null
                            ? l10n.trialBannerNoDate
                            : l10n.trialBannerWithDate(
                                days,
                                DateFormat.yMMMd('ar')
                                    .format(lic.expiresAt!)),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      l10n.trialUpgrade,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline),
                    ),
                    const Icon(Icons.chevron_left,
                        color: Colors.white70, size: 18),
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
