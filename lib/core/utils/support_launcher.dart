import 'package:url_launcher/url_launcher.dart';

import '../network/api_config.dart';

/// The operator contact channels, in the order they're offered to the user.
enum SupportChannel { whatsapp, telegram, email }

/// Opens the operator's contact channels with a prepared message.
///
/// Single home for this logic: the plan-request flow and the settings support
/// sheet both funnel through here, so a fix (or a new channel) lands in both.
class SupportLauncher {
  SupportLauncher._();

  /// WhatsApp's `wa.me` path wants bare international digits — no `+`, spaces,
  /// dashes or a `00` prefix, any of which yield a "phone number is invalid"
  /// page instead of the chat. The value is remote-configurable, so it can't be
  /// assumed clean just because the baked-in default is.
  static String normalizePhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    return digits;
  }

  /// The URI for [channel], or null when that channel isn't configured.
  static Uri? uriFor(
    SupportChannel channel, {
    required String message,
    required String emailSubject,
  }) {
    switch (channel) {
      case SupportChannel.whatsapp:
        final phone = normalizePhone(ApiConfig.supportWhatsApp);
        if (phone.isEmpty) return null;
        return Uri.parse(
            'https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

      case SupportChannel.telegram:
        final tg = ApiConfig.supportTelegram;
        if (tg.isEmpty) return null;
        // The config may hold a full https://t.me/... link or a bare username.
        // Deliberately no `?text=`: t.me ignores it on user/phone links (it only
        // works on share/url and bot start params), so appending it would just
        // produce a URL that silently drops the message. Callers show the text
        // with a copy button instead.
        return Uri.parse(tg.startsWith('http') ? tg : 'https://t.me/$tg');

      case SupportChannel.email:
        if (ApiConfig.supportEmail.isEmpty) return null;
        // Uri(query:) does NOT re-encode an already-percent-encoded string, so
        // building the query by hand here is correct, not a double-encode.
        return Uri(
          scheme: 'mailto',
          path: ApiConfig.supportEmail,
          query: 'subject=${Uri.encodeComponent(emailSubject)}'
              '&body=${Uri.encodeComponent(message)}',
        );
    }
  }

  /// Try to open [channel]. Returns false when it isn't configured, the app
  /// isn't installed, or the launch was refused — callers MUST surface that
  /// rather than fail silently, since the user believes a message was sent.
  static Future<bool> launch(
    SupportChannel channel, {
    required String message,
    required String emailSubject,
  }) async {
    final uri = uriFor(channel, message: message, emailSubject: emailSubject);
    if (uri == null) return false;
    try {
      if (!await canLaunchUrl(uri)) return false;
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Open an arbitrary external link (the developer's website). Same
  /// never-fail-silently contract as [launch].
  static Future<bool> openLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await canLaunchUrl(uri)) return false;
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
