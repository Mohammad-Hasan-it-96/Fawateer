// Phone-local display preferences (theme, text size).
//
// The point of this file is that these no longer live in the shop's database:
// a Drive restore replaces that file wholesale, and a backup taken on another
// phone should not bring its text size along with the books.
import 'package:billing_app/core/settings/device_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a written preference reads back', () async {
    final prefs = DevicePreferences();
    await prefs.write(DevicePreferences.fontScale, 'tiny');
    expect(await prefs.read(DevicePreferences.fontScale), 'tiny');
  });

  test('an unset preference is null, not an error', () async {
    // Callers treat null as "use the default" — a first launch must not be a
    // failure path.
    expect(await DevicePreferences().read(DevicePreferences.themeMode), isNull);
  });

  test('the two settings do not share a key', () async {
    final prefs = DevicePreferences();
    await prefs.write(DevicePreferences.themeMode, 'dark');
    await prefs.write(DevicePreferences.fontScale, 'large');
    expect(await prefs.read(DevicePreferences.themeMode), 'dark');
    expect(await prefs.read(DevicePreferences.fontScale), 'large');
  });

  test('a value survives a fresh instance — it is on disk, not in memory',
      () async {
    await DevicePreferences().write(DevicePreferences.fontScale, 'small');
    expect(await DevicePreferences().read(DevicePreferences.fontScale),
        'small');
  });
}
