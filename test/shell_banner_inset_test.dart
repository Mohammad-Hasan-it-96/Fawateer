// Who owns the status-bar inset when a banner is on screen (AppShell).
//
// The trial/offline banners paint **into** the status bar area and consume that
// inset themselves. If the page below them also consumes it, the inset is spent
// twice and every screen leaves a status-bar-sized empty strip under the banner.
// It was reported as the POS camera's overlay buttons floating well below the
// top of the preview; it was never a POS bug.
//
// AppShell decides using these predicates, which are the same ones the banners
// render by — a second copy of the rule is exactly how the two would drift.
import 'package:billing_app/features/licensing/domain/entities/license_status.dart';
import 'package:billing_app/features/licensing/presentation/bloc/license_bloc.dart';
import 'package:billing_app/features/licensing/presentation/widgets/offline_warning_banner.dart';
import 'package:billing_app/features/licensing/presentation/widgets/trial_banner.dart';
import 'package:flutter_test/flutter_test.dart';

LicenseState _state(LicenseStatus license) => LicenseState(license: license);

void main() {
  final now = DateTime(2026, 8, 9);

  group('trial banner', () {
    // `trialBannerVisible` goes through `LicenseStatus.isActive`, which reads
    // the REAL clock — it takes no injected `now`. So a live licence here has
    // to be dated off `DateTime.now()`, not off the fixed `now` above. The
    // first version used the fixed date and passed for five days, then
    // started failing on a change that had nothing to do with licensing.
    final realNow = DateTime.now();

    test('shows only while a trial is active', () {
      expect(
        trialBannerVisible(_state(LicenseStatus(
            isVerified: true,
            isTrial: true,
            expiresAt: realNow.add(const Duration(days: 5))))),
        isTrue,
      );
      // Paid: no banner, so the page below keeps the status-bar inset.
      expect(
        trialBannerVisible(_state(LicenseStatus(
            isVerified: true,
            expiresAt: realNow.add(const Duration(days: 30))))),
        isFalse,
      );
    });

    test('an expired trial shows nothing — the gate has taken over', () {
      expect(
        trialBannerVisible(_state(LicenseStatus(
            isVerified: true,
            isTrial: true,
            expiresAt: DateTime(2020)))),
        isFalse,
      );
    });
  });

  group('offline banner', () {
    // Same split as above: the offline WINDOW is measured against the injected
    // `now`, but `isActive` inside the predicate reads the real clock, so the
    // expiry has to be real-clock too.
    final realNow = DateTime.now();

    test('shows once the shop has been offline long enough', () {
      final stale = _state(LicenseStatus(
        isVerified: true,
        expiresAt: realNow.add(const Duration(days: 30)),
        lastServerSync: now.subtract(const Duration(days: 5)),
      ));
      expect(offlineBannerVisible(stale, now), isTrue);
    });

    test('stays hidden right after a sync — the common case', () {
      final fresh = _state(LicenseStatus(
        isVerified: true,
        expiresAt: realNow.add(const Duration(days: 30)),
        lastServerSync: now,
      ));
      expect(offlineBannerVisible(fresh, now), isFalse);
    });

    test('never shows for an inactive licence', () {
      // The activation screen is not behind the shell, so a banner there would
      // be both wrong and unreachable.
      final inactive = _state(LicenseStatus(
          lastServerSync: now.subtract(const Duration(days: 5))));
      expect(offlineBannerVisible(inactive, now), isFalse);
    });
  });
}
