import 'package:billing_app/core/network/api_config.dart';
import 'package:billing_app/core/utils/support_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure-logic tests: no plugins, no network. [SupportLauncher.launch] itself
/// needs url_launcher, so only URI construction is covered here.
void main() {
  group('SupportLauncher.normalizePhone', () {
    test('strips the characters wa.me rejects', () {
      expect(SupportLauncher.normalizePhone('+963 959 027 196'), '963959027196');
      expect(SupportLauncher.normalizePhone('963-959-027-196'), '963959027196');
    });

    test('drops an international 00 prefix', () {
      expect(SupportLauncher.normalizePhone('00963959027196'), '963959027196');
    });

    test('leaves an already-clean number alone', () {
      expect(SupportLauncher.normalizePhone('963959027196'), '963959027196');
    });

    test('yields empty for a value with no digits', () {
      expect(SupportLauncher.normalizePhone('n/a'), '');
    });
  });

  group('SupportLauncher.uriFor', () {
    // ApiConfig's contacts are runtime-mutable (the remote config rewrites
    // them), so they can be set directly here.
    setUp(() {
      ApiConfig.supportWhatsApp = '+963 959 027 196';
      ApiConfig.supportTelegram = 'fawateer_support';
      ApiConfig.supportEmail = 'support@example.com';
    });

    test('whatsapp normalizes the phone and encodes the message', () {
      final uri = SupportLauncher.uriFor(SupportChannel.whatsapp,
          message: 'hello world', emailSubject: 's');
      expect(uri.toString(), 'https://wa.me/963959027196?text=hello%20world');
    });

    test('telegram expands a bare username and carries no text param', () {
      final uri = SupportLauncher.uriFor(SupportChannel.telegram,
          message: 'ignored', emailSubject: 's');
      // t.me silently drops ?text= on user links; appending it would imply the
      // message was sent when it wasn't.
      expect(uri.toString(), 'https://t.me/fawateer_support');
    });

    test('telegram passes a full link through unchanged', () {
      ApiConfig.supportTelegram = 'https://t.me/+963959027196';
      final uri = SupportLauncher.uriFor(SupportChannel.telegram,
          message: 'x', emailSubject: 's');
      expect(uri.toString(), 'https://t.me/+963959027196');
    });

    test('mailto does not double-encode the prebuilt query', () {
      final uri = SupportLauncher.uriFor(SupportChannel.email,
          message: 'a b', emailSubject: 'sub ject');
      expect(uri!.scheme, 'mailto');
      expect(uri.path, 'support@example.com');
      expect(uri.query, 'subject=sub%20ject&body=a%20b');
    });

    test('returns null when a channel is not configured', () {
      ApiConfig.supportWhatsApp = '';
      ApiConfig.supportEmail = '';
      expect(
          SupportLauncher.uriFor(SupportChannel.whatsapp,
              message: 'x', emailSubject: 's'),
          isNull);
      expect(
          SupportLauncher.uriFor(SupportChannel.email,
              message: 'x', emailSubject: 's'),
          isNull);
    });
  });
}
