import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// The single sharing transport for the app (Plan 007). Content is rendered
/// upstream (a styled PNG or plain text); this just hands it to the OS share
/// sheet via `share_plus`, so WhatsApp / Telegram / email / SMS / Drive all
/// come for free with no per-channel code.
///
/// Stateless — exposed as static methods (no dependencies to inject).
class ShareService {
  const ShareService._();

  /// Share plain text (e.g. a customer statement or a debt reminder).
  static Future<void> shareText(String text, {String? subject}) {
    return Share.share(text, subject: subject);
  }

  /// Share a PNG image (a rendered receipt / summary card). The bytes are
  /// written to a temp file first because the share sheet takes files, then the
  /// optional [text] rides along as the message body.
  static Future<void> shareImagePng(
    Uint8List bytes, {
    String fileName = 'fawateer_share.png',
    String? text,
    String? subject,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: text,
      subject: subject,
    );
  }

  /// Targeted WhatsApp text to a known [phone] (the debt-reminder path). Falls
  /// back to the generic share sheet if WhatsApp can't be launched (not
  /// installed / link unresolved), so the message is never lost.
  static Future<void> shareTextToWhatsApp({
    required String phone,
    required String text,
  }) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      await shareText(text);
      return;
    }
    final uri = Uri.parse(
        'https://wa.me/$digits?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await shareText(text);
    }
  }
}
