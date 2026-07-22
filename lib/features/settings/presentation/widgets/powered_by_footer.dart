import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/support_launcher.dart';
import '../../../../l10n/app_localizations.dart';

/// Developer credit at the foot of Settings, linking to the company site.
///
/// Deliberately understated: it's an attribution, not a call to action, so it
/// must not compete with the settings rows above it. The website is the only
/// tappable part.
class PoweredByFooter extends StatelessWidget {
  static const String websiteUrl = 'https://evotech-sys.com/';

  const PoweredByFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Divider(color: Theme.of(context).dividerColor, height: 32),
          Text(
            l10n.poweredBy,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final ok = await SupportLauncher.openLink(websiteUrl);
              if (!ok) {
                messenger.showSnackBar(SnackBar(
                  content: Text(l10n.supportLaunchFailed),
                  backgroundColor: Colors.orange.shade800,
                ));
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language,
                      size: 14, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    l10n.visitWebsite,
                    // Always LTR: a bare domain reversed by RTL layout reads as
                    // a different address.
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
