import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_snack.dart';
import '../../../../core/utils/support_launcher.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../licensing/presentation/bloc/license_bloc.dart';

/// Contact-support sheet: shows the exact message that will be sent (with a
/// copy button), then opens the chosen channel.
///
/// The preview isn't decoration — Telegram silently drops a prefilled message,
/// so without a visible copy the user would land in an empty chat with nothing
/// to paste. It also lets them see the device id being shared before sending.
void showSupportSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final license = context.read<LicenseBloc>().state;

  String orDash(String v) => v.trim().isEmpty ? '—' : v.trim();
  final message = '${l10n.supportEmailSubject}\n'
      '${l10n.activationNameLabel}: ${orDash(license.agentName)}\n'
      '${l10n.activationPhoneLabel}: ${orDash(license.agentPhone)}\n'
      '${l10n.deviceIdLabel}: ${orDash(license.deviceId)}';

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _SupportSheet(message: message, l10n: l10n),
  );
}

class _SupportSheet extends StatelessWidget {
  final String message;
  final AppLocalizations l10n;

  const _SupportSheet({required this.message, required this.l10n});

  Future<void> _open(BuildContext context, SupportChannel channel) async {
    // Captured before the async gap — the sheet closes underneath us.
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    final ok = await SupportLauncher.launch(
      channel,
      message: message,
      emailSubject: l10n.supportEmailSubject,
    );
    // Never fail silently: a user who saw nothing happen assumes support was
    // contacted and waits for a reply that will never come.
    if (!ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.supportLaunchFailed),
        backgroundColor: Colors.orange.shade800,
        duration: AppSnackDuration.normal,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(l10n.supportSheetTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(message,
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: scheme.onSurfaceVariant)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: l10n.copy,
                    color: AppTheme.primaryColor,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: message));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.copied)),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _channel(context, Icons.chat, l10n.supportWhatsApp,
                const Color(0xFF25D366), SupportChannel.whatsapp),
            _channel(context, Icons.send, l10n.supportTelegram,
                const Color(0xFF0088CC), SupportChannel.telegram),
            _channel(context, Icons.mail_outline, l10n.supportEmail,
                AppTheme.primaryColor, SupportChannel.email),
          ],
        ),
      ),
    );
  }

  Widget _channel(BuildContext context, IconData icon, String label,
      Color color, SupportChannel channel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _open(context, channel),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }
}
