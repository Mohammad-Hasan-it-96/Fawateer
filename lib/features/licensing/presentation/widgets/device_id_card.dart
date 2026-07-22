import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Shows this device's identifier with a copy button. The user sends it to
/// support to have the device activated (operator-driven flow). Renders nothing
/// until the id is available.
class DeviceIdCard extends StatelessWidget {
  final String deviceId;
  final AppLocalizations l10n;

  const DeviceIdCard({super.key, required this.deviceId, required this.l10n});

  @override
  Widget build(BuildContext context) {
    if (deviceId.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // surfaceContainerHighest, not `surface`: this card sits *on* a surface
        // and needs to read as inset in both modes.
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fingerprint,
                  size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(l10n.deviceIdLabel,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SelectableText(
                  deviceId,
                  style: const TextStyle(
                      fontSize: 12, fontFamily: 'monospace', height: 1.3),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: l10n.copy,
                color: AppTheme.primaryColor,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: deviceId));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n.copied),
                    duration: const Duration(seconds: 1),
                  ));
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(l10n.deviceIdHint,
              style:
                  TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
