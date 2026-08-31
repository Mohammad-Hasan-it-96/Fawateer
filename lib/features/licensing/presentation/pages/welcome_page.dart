import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// The very first screen a new install shows: **is this a new shop, or another
/// phone for a shop that already exists?**
///
/// Before this, every install opened on the name-and-phone registration form,
/// because that is the only question licensing needs answered. But for the
/// second phone in a shop it is the wrong question entirely: the shop is
/// already registered, and the owner's answer is "this is my other till". They
/// had no way to say so — they registered again, landed in the app with an
/// empty catalogue, and had to find Settings → Devices & sync → link, by which
/// point the empty shop had already read as the app being broken.
///
/// Two doors, asked once, before anything is created. Nothing here writes: the
/// choice only decides which flow runs, so a mis-tap costs a Back press.
///
/// It sits inside the licence gate (`app_routes.dart`) rather than in the tab
/// shell, for the same reason the activation form does — it must be reachable
/// exactly when the app is not yet usable, and unreachable once it is.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.storefront,
                    size: 72, color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                Text(
                  l10n.welcomeTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.welcomeSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                // The common case first: most installs are a shop's only phone.
                _ChoiceCard(
                  icon: Icons.add_business,
                  title: l10n.welcomeCreateTitle,
                  subtitle: l10n.welcomeCreateSubtitle,
                  filled: true,
                  onTap: () => context.go('/activation'),
                ),
                const SizedBox(height: 12),
                _ChoiceCard(
                  icon: Icons.phonelink_ring,
                  title: l10n.welcomeJoinTitle,
                  subtitle: l10n.welcomeJoinSubtitle,
                  filled: false,
                  onTap: () => context.go('/welcome/join'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One of the two doors. A whole-card tap target rather than a button with a
/// caption beside it: the subtitle is the part that tells a shopkeeper which
/// one they are, so it has to be inside the thing they press.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = filled ? Colors.white : theme.colorScheme.onSurface;
    return Material(
      color: filled ? AppTheme.primaryColor : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: filled ? 0 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 32, color: fg),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: fg, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: filled
                                ? Colors.white70
                                : theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
