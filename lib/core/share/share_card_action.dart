import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'share_service.dart';
import 'widget_capture.dart';

/// Capture [card] to a PNG and hand it to the OS share sheet. On a capture
/// failure it surfaces a localized snackbar instead of silently doing nothing.
/// One call site per screen keeps the "one Share icon" rule (Plan 007).
Future<void> shareCardAsImage(
  BuildContext context, {
  required Widget card,
  required String fileName,
  String? messageText,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;

  final png = await captureWidgetToPng(context, child: card);
  if (png == null) {
    messenger.showSnackBar(SnackBar(
      content: Text(l10n.shareFailed),
      backgroundColor: Colors.red,
    ));
    return;
  }
  await ShareService.shareImagePng(png, fileName: fileName, text: messageText);
}
