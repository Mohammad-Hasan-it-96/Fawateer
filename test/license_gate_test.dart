// The licence gate — the app's front door.
//
// `licenseGateRedirect` decides, on every navigation and on every licence state
// change, whether a shopkeeper reaches their till, the registration form, the
// plan catalogue, or the new first-run fork. A wrong branch here does not throw
// and does not fail a build: it silently strands someone on a screen. Until the
// decision was lifted out of the GoRouter closure the only way to exercise it
// was to run the app on a phone, which is why the fork's arrival is the moment
// to pin it.
//
// Pure — no widgets, no router, no plugins.
import 'package:billing_app/config/routes/app_routes.dart';
import 'package:billing_app/features/licensing/domain/entities/license_status.dart';
import 'package:billing_app/features/licensing/presentation/bloc/license_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// A licence that is verified and in date.
final _active = LicenseStatus(
  isVerified: true,
  expiresAt: DateTime.now().add(const Duration(days: 30)),
);

LicenseState _state({
  bool bootstrapped = true,
  LicenseStatus license = LicenseStatus.empty,
  String agentName = '',
  bool isBusy = false,
  bool isLinkedMember = false,
}) =>
    LicenseState(
      bootstrapped: bootstrapped,
      license: license,
      agentName: agentName,
      isLinkedMember: isLinkedMember,
      status: isBusy ? LicenseFlowStatus.activating : LicenseFlowStatus.initial,
    );

void main() {
  group('before the first check resolves', () {
    test('everything is held on the splash', () {
      final s = _state(bootstrapped: false);
      expect(licenseGateRedirect(s, '/pos'), '/splash');
      expect(licenseGateRedirect(s, '/welcome'), '/splash');
      expect(licenseGateRedirect(s, '/splash'), isNull);
    });
  });

  group('a new install is asked the fork question first', () {
    // The point of the fork: for a shop's SECOND phone, the registration form
    // asks for a name and a number the owner has already given once, and then
    // drops them into an empty shop they have to go and link by hand. The gate
    // used to send every unregistered device straight there.
    test('an unregistered device lands on /welcome, not the form', () {
      expect(licenseGateRedirect(_state(), '/pos'), '/welcome');
    });

    test('it stays inside the fork while the user is in it', () {
      expect(licenseGateRedirect(_state(), '/welcome'), isNull);
      expect(licenseGateRedirect(_state(), '/welcome/join'), isNull);
    });

    test('the join screen survives a licence state change mid-restore', () {
      // A join ends in a database swap and a restart. If the gate re-evaluated
      // `registered` here it would yank the shopkeeper onto the registration
      // form in the middle of it.
      expect(licenseGateRedirect(_state(agentName: 'محمد'), '/welcome/join'),
          isNull);
    });

    test('the registration form is still reachable from the fork', () {
      // /welcome sends "a new shop" to /activation, and the gate must not
      // bounce it straight back.
      expect(licenseGateRedirect(_state(), '/activation'), isNull);
    });
  });

  group('a registered but unlicensed device', () {
    test('goes to the plan catalogue, never back to the fork', () {
      final s = _state(agentName: 'محمد');
      expect(licenseGateRedirect(s, '/pos'), '/activation/plans');
    });

    test('is moved off the bare name form onto plans', () {
      expect(licenseGateRedirect(_state(agentName: 'محمد'), '/activation'),
          '/activation/plans');
    });

    test('is left alone on the form while a request is in flight', () {
      // Otherwise the form's busy overlay is yanked away mid-activation.
      expect(
          licenseGateRedirect(
              _state(agentName: 'محمد', isBusy: true), '/activation'),
          isNull);
    });
  });

  group('an active subscription', () {
    test('never sits on a gate screen, including the new fork', () {
      final s = _state(license: _active, agentName: 'محمد');
      expect(licenseGateRedirect(s, '/splash'), '/pos');
      expect(licenseGateRedirect(s, '/activation'), '/pos');
      // Added with the fork: without it a phone that becomes licensed while
      // sitting on /welcome/join would stay there, locked out of its own shop.
      expect(licenseGateRedirect(s, '/welcome'), '/pos');
      expect(licenseGateRedirect(s, '/welcome/join'), '/pos');
    });

    test('is left alone everywhere else', () {
      final s = _state(license: _active, agentName: 'محمد');
      expect(licenseGateRedirect(s, '/pos'), isNull);
      expect(licenseGateRedirect(s, '/settings/sync'), isNull);
    });
  });

  group('a guard block is not a payment problem', () {
    test('offline too long routes to verify, not to plans', () {
      // Sending a paid-up shop to the plans page reads as a demand to pay
      // again for something they already bought.
      final s = _state(
        agentName: 'محمد',
        license: LicenseStatus(
          isVerified: true,
          expiresAt: DateTime.now().add(const Duration(days: 30)),
          offlineLimitExceeded: true,
        ),
      );
      expect(licenseGateRedirect(s, '/pos'), '/activation/verify');
      expect(licenseGateRedirect(s, '/activation/verify'), isNull);
    });

    test('a genuinely expired licence falls through to plans', () {
      final s = _state(
        agentName: 'محمد',
        license: LicenseStatus(
          isVerified: true,
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
          offlineLimitExceeded: true,
        ),
      );
      expect(licenseGateRedirect(s, '/pos'), '/activation/plans');
    });
  });

  group('a phone that joined a shop', () {
    // It has no name of its own: the owner's subscription covers it (ADR 0011
    // Decision 2) and the backend creates its row with name and phone null. So
    // `registered` is false, and every branch that keys off it is wrong here.
    test('is never offered "create a new shop"', () {
      // The costly direction: taking that door makes a second business out of
      // a till that already belongs to one.
      final s = _state(isLinkedMember: true);
      expect(licenseGateRedirect(s, '/pos'), '/activation/verify');
      expect(licenseGateRedirect(s, '/pos'), isNot('/welcome'));
    });

    test('is never sent to the plans page either', () {
      // Renewing is the owner's job on the main phone. Asking a member to buy
      // is asking one shop to pay twice — the exact thing the seat-coverage
      // change removed.
      final s = _state(isLinkedMember: true, agentName: 'محمد');
      expect(licenseGateRedirect(s, '/pos'), '/activation/verify');
    });

    test('is left alone once it is on the verify screen', () {
      expect(
          licenseGateRedirect(
              _state(isLinkedMember: true), '/activation/verify'),
          isNull);
    });

    test('reaches its till normally once the licence resolves', () {
      final s = _state(isLinkedMember: true, license: _active);
      expect(licenseGateRedirect(s, '/pos'), isNull);
      expect(licenseGateRedirect(s, '/activation/verify'), '/pos');
    });

    test('falls back to the normal path once its seat is gone', () {
      // A revoke clears the seat credential (SyncScheduler._onRevoked), so the
      // probe reports false and the phone is an ordinary unregistered device
      // again — which is the only way back in.
      expect(licenseGateRedirect(_state(isLinkedMember: false), '/pos'),
          '/welcome');
    });
  });
}
