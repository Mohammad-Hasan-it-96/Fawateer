import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import 'remote_config_service.dart';

/// The "new update available" dialog, shared by the one-time startup prompt
/// (`_UpdateChecker` in main.dart) and the manual check in Settings (tapping
/// the app-version row) — so both always look and behave identically.
///
/// Reads notes + download URL off [service]; call only when
/// [RemoteConfigService.updateAvailable] is true.
Future<void> showUpdateDialog(
    BuildContext context, RemoteConfigService service) async {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return;
  final notes = service.current?.updateNotes ?? const [];
  final url = service.downloadUrl;

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.updateAvailableTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Release notes are optional in the config; without this the
          // dialog would render a title over an empty box.
          if (notes.isEmpty)
            Text(l10n.updateAvailableGeneric)
          else
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• $note'),
              ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.updateLater),
        ),
        FilledButton(
          onPressed: (url == null || url.isEmpty)
              ? null
              : () async {
                  Navigator.of(dialogContext).pop();
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                },
          child: Text(l10n.updateDownload),
        ),
      ],
    ),
  );
}
