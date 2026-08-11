// ManagerPinService (Plan 016 B) against a fake settings store.
//
// What matters here is not that a getter returns a value, but that the PIN
// never reaches storage in readable form, that clearing really clears, and
// that a wrong-PIN streak actually slows an attacker down.
import 'package:billing_app/core/database/daos/settings_dao.dart';
import 'package:billing_app/core/security/manager_pin_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettingsDao implements SettingsDao {
  final Map<String, String> values = {};

  @override
  Future<String?> getValue(String key) async => values[key];

  @override
  Future<void> setValue(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<int> deleteKey(String key) async =>
      values.remove(key) == null ? 0 : 1;

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

void main() {
  late _FakeSettingsDao dao;
  late ManagerPinService service;

  setUp(() {
    dao = _FakeSettingsDao();
    service = ManagerPinService(dao);
  });

  test('the lock is off until a PIN is set', () async {
    // The whole feature is opt-in: a shop that never turns it on must see
    // exactly today's behaviour.
    expect(await service.isPinSet(), isFalse);
  });

  test('the PIN is never stored in readable form', () async {
    // This row travels inside every Google Drive backup, and those are not
    // encrypted.
    await service.setPin('4821');

    expect(dao.values.values.any((v) => v.contains('4821')), isFalse);
    expect(await service.isPinSet(), isTrue);
  });

  test('the right PIN verifies and a wrong one does not', () async {
    await service.setPin('4821');

    expect(await service.verify('4821'), isTrue);
    expect(await service.verify('4822'), isFalse);
  });

  test('a badly formatted PIN is refused rather than stored', () async {
    // Storing '12' would create a lock nobody can open, because the entry
    // field cannot produce fewer than 4 digits.
    expect(await service.setPin('12'), isFalse);
    expect(await service.isPinSet(), isFalse);
  });

  test('changing the PIN keeps the same salt', () async {
    await service.setPin('4821');
    final salt = dao.values['manager_pin_salt'];

    await service.setPin('9999');

    expect(dao.values['manager_pin_salt'], salt);
    expect(await service.verify('9999'), isTrue);
    expect(await service.verify('4821'), isFalse);
  });

  test('clearing removes the hash and the salt together', () async {
    // Leaving the salt behind would let a later backup's hash still be checked
    // against a PIN the shop believes they deleted.
    await service.setPin('4821');
    await service.clear();

    expect(await service.isPinSet(), isFalse);
    expect(dao.values.containsKey('manager_pin_salt'), isFalse);
    expect(dao.values.containsKey('manager_pin_hash'), isFalse);
  });

  test('with no PIN set, verify says no rather than yes', () async {
    // Every caller checks isPinSet first, so arriving here means something is
    // wrong — and the safe answer to "is this person the manager?" is no.
    expect(await service.verify('4821'), isFalse);
  });

  test('repeated wrong tries start a cooldown', () async {
    await service.setPin('4821');

    for (var i = 0; i < ManagerPinService.maxAttempts; i++) {
      expect(await service.verify('0000'), isFalse);
    }

    expect(service.cooldownRemaining, isNotNull);
  });

  test('the cooldown cannot be skipped by knowing the PIN', () async {
    // Otherwise the delay would only slow down someone who is already wrong,
    // which is not who it is for.
    await service.setPin('4821');
    for (var i = 0; i < ManagerPinService.maxAttempts; i++) {
      await service.verify('0000');
    }

    expect(await service.verify('4821'), isFalse);
  });

  test('a correct PIN before the limit clears the count', () async {
    await service.setPin('4821');
    await service.verify('0000');
    await service.verify('0000');
    expect(await service.verify('4821'), isTrue);

    // Four more wrong tries would have tripped the old count; from zero they
    // must not.
    for (var i = 0; i < ManagerPinService.maxAttempts - 1; i++) {
      await service.verify('0000');
    }
    expect(service.cooldownRemaining, isNull);
  });

  test('setting a new PIN clears an active cooldown', () async {
    // Reached only from Settings, which already required the current PIN — so
    // the person doing it has proven who they are.
    await service.setPin('4821');
    for (var i = 0; i < ManagerPinService.maxAttempts; i++) {
      await service.verify('0000');
    }
    expect(service.cooldownRemaining, isNotNull);

    await service.setPin('7777');

    expect(service.cooldownRemaining, isNull);
    expect(await service.verify('7777'), isTrue);
  });
}
