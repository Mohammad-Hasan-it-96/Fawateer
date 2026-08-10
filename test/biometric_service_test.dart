// The fingerprint shortcut past the manager PIN (Plan 016 B).
//
// The system prompt itself can only be exercised on a device. What can — and
// must — be checked here is that the shortcut fails *safe*: with no plugin,
// no sensor, or nothing enrolled, it has to read as "off" and let the PIN
// through, never throw and never accidentally report success.
import 'package:billing_app/core/security/biometric_service.dart';
import 'package:billing_app/core/settings/device_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BiometricService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = BiometricService(DevicePreferences());
  });

  test('the shortcut is off until the owner turns it on', () async {
    // Same rule as the PIN itself: nothing changes for a shop that never opts
    // in.
    expect(await service.isEnabled(), isFalse);
  });

  test('the on/off flag round-trips', () async {
    await service.setEnabled(true);
    expect(await service.isEnabled(), isTrue);

    await service.setEnabled(false);
    expect(await service.isEnabled(), isFalse);
  });

  test('it lives on the phone, not in the shop database', () async {
    // An enrolled fingerprint is a fact about *this handset*. Restoring a
    // backup taken on another phone must not claim this one has a sensor set
    // up, which is why the key is a SharedPreferences key.
    await service.setEnabled(true);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(BiometricService.enabledKey), 'true');
  });

  test('availability reads as false when nothing can answer', () async {
    // There is no platform plugin under `flutter test`, so every call throws.
    // The contract is that this is indistinguishable from a phone with no
    // sensor: the guard simply asks for the PIN.
    expect(await service.isAvailable(), isFalse);
  });

  test('authenticate returns false instead of throwing', () async {
    // A thrown exception here would escape into a dialog's initState and take
    // the guard down with it — leaving a destructive action behind a broken
    // prompt.
    expect(await service.authenticate('reason'), isFalse);
  });

  test('it is never ready while it cannot authenticate', () async {
    // The dangerous shape would be "enabled" alone being enough to draw the
    // fingerprint button on a phone that can't use it.
    await service.setEnabled(true);

    expect(await service.isReady(), isFalse);
  });
}
