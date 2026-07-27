import 'package:billing_app/features/licensing/domain/guards/license_guards.dart';
import 'package:flutter_test/flutter_test.dart';

/// These guards can lock a paying shop out of its own sales data — so the
/// cases that matter most here are the *false positives*: an honest shop that
/// must keep selling. The lock is recoverable (a dedicated screen with Retry),
/// and a soft warning banner shows from day 3 before the day-7 hard lock.
void main() {
  final now = DateTime(2026, 7, 20, 12);

  group('offline grace', () {
    test('never exceeded when the device has never synced', () {
      // Activation handles a never-synced device; this guard must not.
      expect(LicenseGuards.isOfflineLimitExceeded(null, now), isFalse);
    });

    test('a multi-day outage does not lock the shop out', () {
      // The scenario this app ships into: no data for the better part of a week.
      final lastSync = now.subtract(const Duration(days: 6));
      expect(LicenseGuards.isOfflineLimitExceeded(lastSync, now), isFalse);
    });

    test('locks after the 7-day grace', () {
      final lastSync = now.subtract(const Duration(days: 8));
      expect(LicenseGuards.isOfflineLimitExceeded(lastSync, now), isTrue);
    });
  });

  group('offline warning (soft, day 3)', () {
    test('silent when recently synced', () {
      final lastSync = now.subtract(const Duration(days: 2));
      expect(LicenseGuards.isOfflineWarning(lastSync, now), isFalse);
    });

    test('warns after 3 days, well before the hard lock', () {
      final lastSync = now.subtract(const Duration(days: 4));
      expect(LicenseGuards.isOfflineWarning(lastSync, now), isTrue);
      expect(LicenseGuards.isOfflineLimitExceeded(lastSync, now), isFalse,
          reason: 'warning must lead the lock, not coincide with it');
      expect(LicenseGuards.daysOffline(lastSync, now), 4);
    });

    test('never warns when never synced', () {
      expect(LicenseGuards.isOfflineWarning(null, now), isFalse);
      expect(LicenseGuards.daysOffline(null, now), isNull);
    });
  });

  group('clock tamper (trusted server time)', () {
    test('no trusted time means no verdict', () {
      expect(LicenseGuards.isTimeTampered(null, now), isFalse);
    });

    test('a clock ahead of server time is not tampering', () {
      // Rolling *forward* brings expiry closer; only backwards buys free usage.
      final trusted = now.subtract(const Duration(days: 5));
      expect(LicenseGuards.isTimeTampered(trusted, now), isFalse);
    });

    test('an hours-off clock is drift, not tampering', () {
      // A flat battery or a timezone correction, not an attack.
      final trusted = now.add(const Duration(hours: 6));
      expect(LicenseGuards.isTimeTampered(trusted, now), isFalse);
    });

    test('a rollback far enough to dodge an expiry is still caught', () {
      final trusted = now.add(const Duration(days: 30));
      expect(LicenseGuards.isTimeTampered(trusted, now), isTrue);
    });

    test('skew offset compensates a device clock that runs behind', () {
      // Device clock is 3 days behind the server — recorded as a positive
      // offset at sync time. Without compensation this legitimate skew would
      // read as a 3-day rollback and trip the 48h threshold.
      const skew = Duration(days: 3);
      final trusted = now.add(skew);
      expect(
          LicenseGuards.isTimeTampered(trusted, now,
              timeOffsetSeconds: skew.inSeconds),
          isFalse);
      // And an actual further rollback on top of the skew is still caught.
      final rolledBack = now.subtract(const Duration(days: 3));
      expect(
          LicenseGuards.isTimeTampered(trusted, rolledBack,
              timeOffsetSeconds: skew.inSeconds),
          isTrue);
    });
  });

  group('clock rollback (offline max-seen anchor)', () {
    test('no anchor means no verdict', () {
      expect(LicenseGuards.isClockRolledBack(null, now), isFalse);
    });

    test('normal forward time never trips', () {
      final maxSeen = now.subtract(const Duration(minutes: 5));
      expect(LicenseGuards.isClockRolledBack(maxSeen, now), isFalse);
    });

    test('small corrections are tolerated', () {
      final maxSeen = now.add(const Duration(hours: 6));
      expect(LicenseGuards.isClockRolledBack(maxSeen, now), isFalse);
    });

    test('a big rollback trips even with no recent server sync', () {
      // The case the trusted-time check cannot see: the anchor is pure device
      // time, so dodging expiry offline by rewinding the clock is caught too.
      final maxSeen = now.add(const Duration(days: 10));
      expect(LicenseGuards.isClockRolledBack(maxSeen, now), isTrue);
    });
  });
}
