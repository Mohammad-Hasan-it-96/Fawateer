import 'package:billing_app/features/licensing/domain/guards/license_guards.dart';
import 'package:flutter_test/flutter_test.dart';

/// These guards can lock a paying shop out of its own sales data, and the
/// lockout surfaces no explanation — so the cases that matter most here are the
/// *false positives*: an honest shop that must keep selling.
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

    test('still enforced eventually', () {
      final lastSync = now.subtract(const Duration(days: 31));
      expect(LicenseGuards.isOfflineLimitExceeded(lastSync, now), isTrue);
    });
  });

  group('clock tamper', () {
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
  });
}
