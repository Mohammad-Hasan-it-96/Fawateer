// Reading `GET /api/v1/sync/devices` (Plan 002).
//
// This layer had no tests, and it is the one that meets production. Everything
// else in the sync feature is exercised against a fake server whose responses
// we wrote ourselves — which proves the client agrees with itself, not that it
// agrees with Laravel. The two failures below both come from real ambiguity in
// the pinned contract, and both are silent: the screen renders, looks right,
// and states something false.
import 'package:billing_app/features/sync/domain/entities/sync_device.dart';
import 'package:billing_app/features/sync/domain/entities/sync_device_registry.dart';
import 'package:billing_app/features/sync/domain/entities/sync_seat_role.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the repository passes in: `data` when it is a map, else `{}`.
Map<String, dynamic> dataOf(Map<String, dynamic> envelope) {
  final d = envelope['data'];
  return d is Map<String, dynamic> ? d : <String, dynamic>{};
}

SyncDeviceRegistry parse(Map<String, dynamic> envelope, {String? seat}) =>
    SyncDeviceRegistry.fromJson(dataOf(envelope),
        envelope: envelope, currentSeat: seat);

void main() {
  group('the allowance survives whichever envelope the server uses', () {
    // The pinned 2026-08-15 shape is `data[]` — a LIST of seats. So the
    // allowance cannot be inside `data`; it has to sit beside it.
    test('data is a list, allowance beside it', () {
      final registry = parse({
        'data': [
          {'uuid': 's1', 'role': 'owner'},
          {'uuid': 's2', 'role': 'member'},
        ],
        'device_allowance': 3,
      });

      expect(registry.devices.length, 2);
      expect(registry.allowance, 3);
      expect(registry.used, 2);
      expect(registry.isAtCap, isFalse);
    });

    test('data is a list, allowance under meta', () {
      final registry = parse({
        'data': [
          {'uuid': 's1', 'role': 'owner'}
        ],
        'meta': {'device_allowance': 3},
      });
      expect(registry.allowance, 3);
    });

    test('data is a map holding both', () {
      final registry = parse({
        'data': {
          'devices': [
            {'uuid': 's1', 'role': 'owner'}
          ],
          'device_allowance': 5,
        }
      });
      expect(registry.devices.single.uuid, 's1');
      expect(registry.allowance, 5);
    });

    test('a missing allowance stays NULL, never zero', () {
      // Null means "the server did not say". Zero would mean "you have no
      // seats", and `isAtCap` on zero would lock an owner out of their own
      // plan over information nobody gave us.
      final registry = parse({
        'data': [
          {'uuid': 's1', 'role': 'owner'}
        ]
      });
      expect(registry.allowance, isNull);
      expect(registry.isAtCap, isFalse);
      expect(registry.hasAllowance, isFalse);
    });

    test('a string allowance is still a number', () {
      // PHP happily serialises an integer column as a string.
      final registry = parse({'data': const [], 'device_allowance': '3'});
      expect(registry.allowance, 3);
    });
  });

  group('a seat row', () {
    test('reads last_used_at — the name the shipped migration uses', () {
      // The 2026-07-27 design said `last_seen_at`; the 2026-08-11 reply
      // re-read the migration and the column is `last_used_at`. Reading only
      // the design's name leaves every row saying "not seen yet", which does
      // not read as a parsing bug — it reads as the server never hearing from
      // the other phone, i.e. as sync being broken.
      final device = SyncDevice.fromJson(const {
        'uuid': 's2',
        'role': 'member',
        'last_used_at': '2026-08-15T09:30:00Z',
      });
      expect(device.lastSeenAt, isNotNull);
    });

    test('still reads last_seen_at, so an older server does not go blank', () {
      final device = SyncDevice.fromJson(const {
        'uuid': 's2',
        'role': 'member',
        'last_seen_at': '2026-08-15T09:30:00Z',
      });
      expect(device.lastSeenAt, isNotNull);
    });

    test('an epoch-seconds timestamp is not read as milliseconds', () {
      // 1_000_000_000 ms is 1970; as seconds it is 2001. Getting this wrong
      // would bucket every phone as "last used 20,000 days ago".
      final device = SyncDevice.fromJson(
          const {'uuid': 's2', 'role': 'member', 'last_used_at': 1786000000});
      expect(device.lastSeenAt!.year, greaterThan(2020));
    });

    test('takes the owner name from `name`', () {
      final device = SyncDevice.fromJson(
          const {'uuid': 's2', 'role': 'member', 'name': 'الكاشير'});
      expect(device.label, 'الكاشير');
    });

    test('an empty name is null, not an empty title', () {
      // The server stores empty-after-trim as NULL; a "" that reached the UI
      // would render as a blank row rather than falling back to the role.
      final device =
          SyncDevice.fromJson(const {'uuid': 's2', 'role': 'member', 'name': ''});
      expect(device.label, isNull);
    });

    test('this phone is flagged, and is never revocable', () {
      final rows = [
        SyncDevice.fromJson(const {'uuid': 's1', 'role': 'owner'}, currentSeat: 's2'),
        SyncDevice.fromJson(const {'uuid': 's2', 'role': 'member'}, currentSeat: 's2'),
      ];
      expect(rows[1].isCurrent, isTrue);
      expect(rows[1].isRevocable, isFalse,
          reason: 'a phone revoking itself is never what was meant');
      // The owner seat is refused server-side too, so it is never offered.
      expect(rows[0].isRevocable, isFalse);
      expect(rows[0].role, SyncSeatRole.owner);
    });

    test('a row with no uuid is dropped rather than shown unusable', () {
      // Every action on this screen is keyed by seat uuid, so a row without
      // one is a button that cannot work.
      final registry = parse({
        'data': [
          {'role': 'member'},
          {'uuid': 's2', 'role': 'member'},
        ]
      });
      expect(registry.devices.map((d) => d.uuid), ['s2']);
    });
  });
}
