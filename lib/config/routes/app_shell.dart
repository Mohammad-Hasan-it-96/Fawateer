import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/app_snack.dart';
import '../../l10n/app_localizations.dart';
import '../../features/licensing/presentation/bloc/license_bloc.dart';
import '../../features/licensing/presentation/widgets/offline_warning_banner.dart';
import '../../features/licensing/presentation/widgets/trial_banner.dart';

class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppShell({super.key, required this.navigationShell});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// True while a second back press would actually quit. Armed by the first
  /// press and disarmed by [_exitTimer], rather than by comparing wall-clock
  /// timestamps — the flag then expires on exactly the same clock that hides
  /// the snackbar, and it stays deterministic under test.
  bool _exitArmed = false;
  Timer? _exitTimer;

  /// How long the second back press has to arrive to actually exit. Kept equal
  /// to the hint snackbar's duration so the prompt vanishes exactly when the
  /// window closes — a visible hint that no longer works is worse than none.
  static const Duration _kExitWindow = AppSnackDuration.brief;

  @override
  void dispose() {
    _exitTimer?.cancel();
    super.dispose();
  }

  /// Handle a back press the tab branches didn't consume.
  ///
  /// Only reached when the current branch has nothing left to pop: Flutter asks
  /// the innermost navigator first, so a pushed page (`/products/add`,
  /// `/settings/cashbox`) still pops normally and never gets here. What arrives
  /// here is a back press on a **tab root**, which previously bubbled to the
  /// system and killed the app instantly — mid-sale, from any tab.
  void _handleBack() {
    final l10n = AppLocalizations.of(context)!;

    // From any other tab, back means "go home" rather than "quit".
    if (widget.navigationShell.currentIndex != 0) {
      widget.navigationShell.goBranch(0);
      return;
    }

    // Already on the POS tab: require a confirming second press. A cashier's
    // thumb rests near the back button all day, so one stray tap must never
    // close the till.
    if (_exitArmed) {
      SystemNavigator.pop();
      return;
    }
    _exitArmed = true;
    _exitTimer?.cancel();
    _exitTimer = Timer(_kExitWindow, () => _exitArmed = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l10n.pressBackAgainToExit),
        duration: _kExitWindow,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      // Never let a back press pop the shell itself — that closes the app.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        body: BlocBuilder<LicenseBloc, LicenseState>(
          builder: (context, licenseState) {
            // A visible banner paints **into** the status bar area and consumes
            // that inset itself. Without telling the page below, the inset is
            // spent twice: every screen then leaves a status-bar-sized empty
            // strip under the banner. It showed up as the POS camera's overlay
            // buttons floating well below the top of the preview, but it was
            // never a POS bug — it was every page, on every trial device.
            final bannerShown = trialBannerVisible(licenseState) ||
                offlineBannerVisible(licenseState, DateTime.now());
            return Column(
              children: [
                // Persistent free-trial banner (renders nothing outside a trial).
                const TrialBanner(),
                // "Too long offline, connect soon" warning (renders nothing when
                // recently synced) — the fair warning before the 7-day hard lock.
                const OfflineWarningBanner(),
                Expanded(
                  // Always a MediaQuery, only the flag changes: inserting and
                  // removing a wrapper here would remount the whole branch when
                  // a trial ends — which for the POS means tearing down and
                  // restarting the camera mid-shift.
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: bannerShown,
                    child: widget.navigationShell,
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) => widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.point_of_sale_outlined),
              selectedIcon: const Icon(Icons.point_of_sale),
              label: l10n.posTab,
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: const Icon(Icons.insights),
              label: l10n.reportsTab,
            ),
            NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined),
              selectedIcon: const Icon(Icons.inventory_2),
              label: l10n.productsTab,
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_alt_outlined),
              selectedIcon: const Icon(Icons.people_alt),
              label: l10n.customersTab,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: l10n.settingsTab,
            ),
          ],
        ),
      ),
    );
  }
}
