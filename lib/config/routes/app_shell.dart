import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../features/licensing/presentation/widgets/trial_banner.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Column(
        children: [
          // Persistent free-trial banner (renders nothing outside a trial).
          const TrialBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) =>
            navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.point_of_sale_outlined),
            selectedIcon: const Icon(Icons.point_of_sale),
            label: l10n.posTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: l10n.historyTab,
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
    );
  }
}
