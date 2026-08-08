// Which push means what (Plan 002, Phase 1 — the sync doorbell).
//
// The service itself needs a Firebase project and cannot run here, so the
// routing decision is a pure function and this tests that. It is the part with
// a consequence: one branch runs a silent sync pass, the other re-checks the
// subscription and pops a green "subscription activated" banner.
import 'package:billing_app/features/licensing/data/services/push_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the sync doorbell runs a pass, silently', () {
    expect(classifyPushMessage({'type': 'sync_changes_available'}),
        PushMessageKind.sync);
  });

  test('a revoked device is told through the same doorbell', () {
    // No special handling: the ring says "come and look", the device looks, and
    // the pass comes back DEVICE_REVOKED — which is what drops the dead seat.
    // A separate client-side path would be a second way to become unenrolled,
    // and the pass has to handle it anyway for the device that was offline when
    // the ring went out.
    expect(classifyPushMessage({'type': 'sync_device_revoked'}),
        PushMessageKind.sync);
  });

  test('a sync doorbell is NEVER mistaken for a licence event', () {
    // The load-bearing one. The licence branch ends in a subscription re-check
    // and a visible banner; a sync type falling through to it would pop
    // "subscription activated" on this till for every sale the other one makes.
    for (final type in const ['sync_changes_available', 'sync_device_revoked']) {
      expect(classifyPushMessage({'type': type}),
          isNot(PushMessageKind.license));
    }
  });

  test('licence types still unlock the app live', () {
    for (final type in const [
      'new_plan_activated',
      'subscription_activated',
      'license_updated',
    ]) {
      expect(classifyPushMessage({'type': type}), PushMessageKind.license);
    }
  });

  test('an unknown or absent type does nothing', () {
    // A plain marketing notification the OS has already shown. Falling through
    // to either branch would sync or re-check on every one of them.
    expect(classifyPushMessage({}), PushMessageKind.ignored);
    expect(classifyPushMessage({'type': ''}), PushMessageKind.ignored);
    expect(classifyPushMessage({'type': 'promo'}), PushMessageKind.ignored);
    expect(classifyPushMessage({'body': 'hello'}), PushMessageKind.ignored);
  });

  test('whitespace around a type does not break routing', () {
    // FCM data values are strings assembled server-side; a stray newline in a
    // payload template would otherwise silently disable the doorbell for every
    // device, with nothing to see in any log.
    expect(classifyPushMessage({'type': ' sync_changes_available\n'}),
        PushMessageKind.sync);
  });

  test('a non-string type is tolerated, not thrown on', () {
    // The map is `Map<String, dynamic>` and the server controls it. A crash in
    // the message handler is not a fair response to a malformed payload.
    expect(classifyPushMessage({'type': 7}), PushMessageKind.ignored);
    expect(classifyPushMessage({'type': null}), PushMessageKind.ignored);
  });
}
