import 'dart:convert';
import 'dart:io';

import 'package:billing_app/core/error/failure.dart';
import 'package:billing_app/core/network/sync_api_client.dart';
import 'package:billing_app/features/licensing/data/datasources/license_local_storage.dart';
import 'package:billing_app/features/licensing/data/services/device_identity_service.dart';
import 'package:billing_app/features/sync/data/repositories/sync_enrollment_repository_impl.dart';
import 'package:billing_app/features/sync/data/sync_credential_store.dart';
import 'package:billing_app/features/sync/domain/entities/sync_seat_role.dart';
import 'package:billing_app/features/sync/domain/sync_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A device identity that yields a fixed id, so the enrollment tests are pure
/// host tests (no `device_info_plus` platform channel).
class _FakeIdentity extends DeviceIdentityService {
  const _FakeIdentity(this._id);
  final String _id;
  @override
  Future<String> getDeviceId() async => _id;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const deviceId = 'device-abc-123';
  late SyncCredentialStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = SyncCredentialStore();
  });

  /// A repository wired to a canned HTTP handler.
  SyncEnrollmentRepositoryImpl repoWith(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return SyncEnrollmentRepositoryImpl(
      SyncApiClient(client: MockClient(handler), baseUrl: 'https://x/api/v1'),
      store,
      const _FakeIdentity(deviceId),
      LicenseLocalStorage(),
    );
  }

  http.Response json(Object body, int status) =>
      http.Response(jsonEncode(body), status,
          headers: {'content-type': 'application/json'});

  group('owner onboarding', () {
    test('establishes a business, stores the owner session, seeds the cursor',
        () async {
      late http.Request captured;
      final repo = repoWith((request) async {
        captured = request;
        return json({
          'data': {
            'sync_token': 'evosync_owner_tok',
            'seat': {'uuid': 'seat-1', 'role': 'owner', 'device_id': deviceId},
            'business_uuid': 'biz-1',
            'device_allowance': 3,
            'bootstrap': {'cursor': 0, 'snapshot_url': null, 'snapshot_sha256': null},
          }
        }, 201);
      });

      final result = await repo.establishAsOwner(pushToken: 'fcm-xyz');

      // It targeted the owner-onboarding endpoint with the licensing identity.
      expect(captured.method, 'POST');
      expect(captured.url.path, endsWith('/sync/business'));
      final sent = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(sent['app_name'], 'Fawateer');
      expect(sent['device_id'], deviceId);
      // `fcm_token`, matching the contract's
      // `{join_token, device_id, fcm_token, app_version}`. Without this field
      // the server has no way to reach the seat and the doorbell can never ring.
      expect(sent['fcm_token'], 'fcm-xyz');

      // It returned the owner outcome…
      final outcome = result.getOrElse((_) => throw StateError('expected Right'));
      expect(outcome.session.role, SyncSeatRole.owner);
      expect(outcome.session.isOwner, isTrue);
      expect(outcome.session.deviceAllowance, 3);
      expect(outcome.bootstrap.cursor, 0);
      expect(outcome.bootstrap.hasSnapshot, isFalse);

      // …and persisted the credential for later calls.
      final stored = await store.load();
      expect(stored?.syncToken, 'evosync_owner_tok');
      expect(stored?.businessUuid, 'biz-1');
      expect(stored?.role, SyncSeatRole.owner);
    });

    test('maps SUBSCRIPTION_REQUIRED to a typed failure and stores nothing',
        () async {
      final repo = repoWith((_) async => json({
            'error': {
              'code': 'SUBSCRIPTION_REQUIRED',
              'message': 'no sub',
              'details': [],
              'trace_id': 't',
            }
          }, 403));

      final result = await repo.establishAsOwner();

      final failure = result.swap().getOrElse((_) => throw StateError('expected Left'));
      expect(failure, isA<SyncFailure>());
      expect((failure as SyncFailure).error, SyncError.subscriptionRequired);
      expect(await store.load(), isNull);
    });
  });

  group('member join', () {
    test('redeems a join token and stores the member session', () async {
      late http.Request captured;
      final repo = repoWith((request) async {
        captured = request;
        return json({
          'data': {
            'sync_token': 'evosync_member_tok',
            'seat': {'uuid': 'seat-2', 'role': 'member', 'device_id': deviceId},
            'business_uuid': 'biz-1',
            'bootstrap': {'cursor': 42, 'snapshot_url': 'https://x/dl', 'snapshot_sha256': 'abc'},
          }
        }, 201);
      });

      final result = await repo.joinBusiness('evojoin_code');

      expect(captured.url.path, endsWith('/sync/enroll'));
      expect((jsonDecode(captured.body) as Map)['join_token'], 'evojoin_code');

      final outcome = result.getOrElse((_) => throw StateError('expected Right'));
      expect(outcome.session.role, SyncSeatRole.member);
      expect(outcome.bootstrap.cursor, 42);
      expect(outcome.bootstrap.hasSnapshot, isTrue);
      expect((await store.load())?.syncToken, 'evosync_member_tok');
    });

    test('maps ALLOWANCE_EXCEEDED to a typed failure', () async {
      final repo = repoWith((_) async => json({
            'error': {'code': 'ALLOWANCE_EXCEEDED', 'message': 'full'}
          }, 409));

      final failure = (await repo.joinBusiness('evojoin_code'))
          .swap()
          .getOrElse((_) => throw StateError('expected Left'));
      expect((failure as SyncFailure).error, SyncError.allowanceExceeded);
    });
  });

  group('the doorbell needs a token to ring', () {
    test('enrollment falls back to the token licensing already cached',
        () async {
      // Nothing passes `pushToken` — the BLoC does not know about FCM and
      // should not. Before this fallback the optional parameter had no caller
      // at all, so every enrollment went up with the field absent and the
      // server had no way to reach the seat: the receive side was wired and
      // unreachable.
      SharedPreferences.setMockInitialValues({'lic_push_token': 'cached-fcm'});

      late http.Request captured;
      final repo = repoWith((request) async {
        captured = request;
        return json({
          'data': {
            'sync_token': 't',
            'seat': {'uuid': 's', 'role': 'member'},
            'business_uuid': 'b',
            'bootstrap': {'cursor': 0},
          }
        }, 201);
      });

      await repo.joinBusiness('evojoin_code');

      expect((jsonDecode(captured.body) as Map)['fcm_token'], 'cached-fcm');
    });

    test('an explicit token wins over the cache', () async {
      SharedPreferences.setMockInitialValues({'lic_push_token': 'stale'});

      late http.Request captured;
      final repo = repoWith((request) async {
        captured = request;
        return json({
          'data': {
            'sync_token': 't',
            'seat': {'uuid': 's', 'role': 'owner'},
            'business_uuid': 'b',
            'bootstrap': {'cursor': 0},
          }
        }, 201);
      });

      await repo.establishAsOwner(pushToken: 'fresh');

      expect((jsonDecode(captured.body) as Map)['fcm_token'], 'fresh');
    });

    test('no token anywhere still enrolls, without the field', () async {
      // A device with no Play Services, or one enrolling before its first token
      // arrives. It syncs on its own triggers and simply waits for the timer
      // instead of being told — refusing to enroll over a notification channel
      // would be absurd.
      late http.Request captured;
      final repo = repoWith((request) async {
        captured = request;
        return json({
          'data': {
            'sync_token': 't',
            'seat': {'uuid': 's', 'role': 'owner'},
            'business_uuid': 'b',
            'bootstrap': {'cursor': 0},
          }
        }, 201);
      });

      final result = await repo.establishAsOwner();

      expect(result.isRight(), isTrue);
      expect((jsonDecode(captured.body) as Map).containsKey('fcm_token'), isFalse);
    });
  });

  test('an offline transport maps to a retryable NetworkFailure', () async {
    final repo = repoWith((_) async => throw const SocketException('offline'));

    final failure = (await repo.establishAsOwner())
        .swap()
        .getOrElse((_) => throw StateError('expected Left'));
    expect(failure, isA<NetworkFailure>());
  });
}
