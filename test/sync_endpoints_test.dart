// The URLs the sync client actually asks for.
//
// **This is the one thing the rest of the sync suite structurally cannot
// check.** `integration_test/sync_engine_test.dart` and `bootstrap_test.dart`
// drive a `SyncTransport` implemented as an in-memory relay — two real
// databases converging, which is the right way to prove the merge — but a relay
// has no URL. `SyncApiTransport`, the only place a path is written down, is
// never on that code path at all. So the app could name every endpoint wrongly
// and every sync test would still pass.
//
// It did. The client was built against the 2026-07-27 design, which named the
// endpoints `/sync/push`, `/sync/pull`, `/sync/enroll/token` and a guessed
// `/sync/enroll/seed`. What shipped is `POST|GET /sync/changes`,
// `POST /sync/join-tokens` and `POST /sync/join-tokens/{t}/bootstrap`
// (confirmed 2026-08-11, verified against production). All four calls 404'd.
//
// A 404 is a *route* error: it carries no typed code, so it fell to
// `SyncError.server` and the shop was told "something went wrong, try again" —
// the same message a real outage gives. Every sync pass on a real phone had
// failed from the first day, and nothing in the app, the suite or the screen
// said which of the two it was.
import 'package:billing_app/core/network/sync_api_client.dart';
import 'package:billing_app/features/licensing/data/datasources/license_local_storage.dart';
import 'package:billing_app/features/licensing/data/services/device_identity_service.dart';
import 'package:billing_app/features/sync/data/bootstrap_service.dart';
import 'package:billing_app/features/sync/data/repositories/sync_enrollment_repository_impl.dart';
import 'package:billing_app/features/sync/data/sync_api_transport.dart';
import 'package:billing_app/features/sync/data/sync_credential_store.dart';
import 'package:billing_app/features/sync/domain/entities/sync_change.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kBase = 'https://api.evotech-sys.com/api/v1';

/// Records what was asked for and answers with an empty success envelope.
class _Recorder {
  final List<String> calls = [];

  /// Overrides the canned reply, so a test can assert on parsing as well as on
  /// the URL.
  String body;

  _Recorder({this.body = '{"data":{}}'});

  MockClient get client => MockClient((request) async {
        calls.add('${request.method} ${request.url}');
        return http.Response(body, 200,
            headers: {'content-type': 'application/json'});
      });

  String get only {
    expect(calls.length, 1, reason: 'exactly one request per action');
    return calls.single;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the sync engine talks to /sync/changes, not /sync/push|pull', () {
    test('pushing posts to sync/changes', () async {
      final rec = _Recorder();
      final transport = SyncApiTransport(
          SyncApiClient(client: rec.client, baseUrl: _kBase), () async => 't');

      await transport.push(const [
        SyncChange(
          table: 'products',
          rowUuid: 'p1',
          op: SyncChange.opUpsert,
          payload: {'id': 'p1'},
          authoredHlc: '000001',
          originDevice: 'd1',
        )
      ]);

      expect(rec.only, 'POST $_kBase/sync/changes');
    });

    test('pulling names the position `cursor`, which is what the server reads',
        () async {
      // The design (ADR 0011 §9) writes the route as `?since=<seq>` and that is
      // what we sent until 2026-08-31. Their `SyncChangeController::pull`
      // validates and reads `cursor`; an unknown `since` is simply dropped, so
      // every pull was answered from seq 0. HTTP 200 with a full, valid page —
      // nothing to notice until retention prunes and cursor 0 falls below the
      // pruned watermark, at which point a device that was never behind is told
      // CURSOR_TOO_OLD and stops pulling for good.
      final rec = _Recorder();
      final transport = SyncApiTransport(
          SyncApiClient(client: rec.client, baseUrl: _kBase), () async => 't');

      await transport.pull(since: 42, limit: 7);

      expect(rec.only, contains('cursor=42'),
          reason: 'the shipped server reads `cursor`; `since` is ignored');
      expect(rec.only, contains('limit=7'));
    });

    test('an empty push makes no request at all', () async {
      // Not a path assertion, but it is what stops the 5-minute backstop timer
      // waking the server on a shop that sold nothing.
      final rec = _Recorder();
      final transport = SyncApiTransport(
          SyncApiClient(client: rec.client, baseUrl: _kBase), () async => 't');

      await transport.push(const []);

      expect(rec.calls, isEmpty);
    });
  });

  group('the pull envelope is data[] + meta, not a flat body', () {
    // Read off production on 2026-08-16:
    //   {"data":[…rows…],"meta":{"next_cursor":0,"has_more":false}}
    // The design document said `{changes, next_cursor, has_more}` at the top
    // level. Reading the design's shape against the real body is WORSE than a
    // wrong URL, because it returns HTTP 200: every pull yields an empty page,
    // the device says "up to date", and the other phone's sales are never seen.
    // Nothing errors, so nothing is ever investigated.
    SyncApiTransport transportOn(_Recorder rec) => SyncApiTransport(
        SyncApiClient(client: rec.client, baseUrl: _kBase), () async => 't');

    test('rows are read from data[] and the cursor from meta', () async {
      final rec = _Recorder(body: '''
        {"data":[{"table_name":"products","row_uuid":"p1","op":"upsert",
                  "payload":{"id":"p1","name":"رز"},
                  "authored_hlc":"0001","origin_device":"d9","seq":7}],
         "meta":{"next_cursor":12,"has_more":true}}''');

      final page = await transportOn(rec).pull(since: 0);

      expect(page.changes.single.rowUuid, 'p1');
      expect(page.changes.single.seq, 7);
      expect(page.nextCursor, 12, reason: 'the EXAMINED seq, out of meta');
      expect(page.hasMore, isTrue);
    });

    test('an empty page leaves the cursor where the server put it', () async {
      // The exact body production returned for a shop that has pushed nothing.
      final rec = _Recorder(
          body: '{"data":[],"meta":{"next_cursor":0,"has_more":false}}');

      final page = await transportOn(rec).pull(since: 0);

      expect(page.changes, isEmpty);
      expect(page.nextCursor, 0);
      expect(page.hasMore, isFalse);
    });

    test('a missing cursor holds position rather than replaying history',
        () async {
      final rec = _Recorder(body: '{"data":[]}');
      final page = await transportOn(rec).pull(since: 40);
      expect(page.nextCursor, 40, reason: 'never 0');
    });

    test('the flat design shape still parses', () async {
      // Kept as a fallback: it costs nothing, and if a deploy ever answers the
      // documented shape the alternative is silently syncing nothing.
      final rec = _Recorder(body: '''
        {"changes":[{"table_name":"products","row_uuid":"p1",
                     "payload":{"id":"p1"},"authored_hlc":"1","origin_device":"d"}],
         "next_cursor":5,"has_more":false}''');

      final page = await transportOn(rec).pull(since: 0);

      expect(page.changes.single.rowUuid, 'p1');
      expect(page.nextCursor, 5);
    });

    test('push buckets are read out of data, and flat as a fallback', () async {
      const row = SyncChange(
        table: 'products',
        rowUuid: 'p1',
        op: SyncChange.opUpsert,
        payload: {'id': 'p1'},
        authoredHlc: '0001',
        originDevice: 'd1',
      );

      final nested = _Recorder(
          body: '{"data":{"accepted":["p1"],"rejected":[],"conflicts":["p2"]}}');
      var result = await transportOn(nested).push(const [row]);
      expect(result.accepted, {'p1'});
      expect(result.conflicts, {'p2'});

      final flat = _Recorder(body: '{"accepted":["p1"],"rejected":["p3"]}');
      result = await transportOn(flat).push(const [row]);
      expect(result.accepted, {'p1'});
      expect(result.rejected, {'p3'});
    });
  });

  group('the push verdict is data.applied[], not data.accepted[]', () {
    // The 2026-07-27 design and ADR 0011 §9 both promise
    // "per-row accepted|rejected|conflict". The shipped server answers
    //   {"data":{"applied":[{"row_uuid","authored_hlc","seq","duplicate"}],
    //            "last_seq":N}}
    // and has no rejected/conflicts buckets at all — every pushed row is
    // appended, and a re-push comes back `duplicate: true` on its original seq.
    //
    // Reading the design's names finds three empty buckets, which the engine
    // reads as "the server accepted nothing": the push watermark never
    // advances, so the device re-uploads its whole backlog on every trigger,
    // forever, while the screen reports "0 changes sent". The rows do land, so
    // there is no error and no missing data — only a device that never stops
    // talking and never admits it worked.
    SyncApiTransport transportOn(_Recorder rec) => SyncApiTransport(
        SyncApiClient(client: rec.client, baseUrl: _kBase), () async => 't');

    const one = SyncChange(
      table: 'products',
      rowUuid: 'p1',
      op: SyncChange.opUpsert,
      payload: {'id': 'p1'},
      authoredHlc: '000001',
      originDevice: 'd1',
    );

    test('applied[] row_uuids count as accepted', () async {
      final rec = _Recorder(body: '''
        {"data":{"applied":[{"row_uuid":"p1","authored_hlc":"000001",
                             "seq":4,"duplicate":false}],
                 "last_seq":4}}''');

      final result = await transportOn(rec).push(const [one]);

      expect(result.accepted, {'p1'},
          reason: 'without this the push watermark never moves');
      expect(result.rejected, isEmpty);
      expect(result.conflicts, isEmpty);
    });

    test('a duplicate is still accepted — it landed the first time', () async {
      // Idempotency (§F2) replies with the ORIGINAL seq and `duplicate: true`.
      // Treating that as anything but accepted would stall the watermark on
      // exactly the rows a retry is meant to settle.
      final rec = _Recorder(body: '''
        {"data":{"applied":[{"row_uuid":"p1","authored_hlc":"000001",
                             "seq":4,"duplicate":true}],
                 "last_seq":9}}''');

      expect((await transportOn(rec).push(const [one])).accepted, {'p1'});
    });

    test("the design's accepted/rejected/conflicts still parse", () async {
      // Kept as a fallback rather than deleted: if the arbitration buckets are
      // ever built they are additive, not a reinterpretation of `applied`.
      final rec = _Recorder(body: '''
        {"data":{"accepted":["p1"],"rejected":[{"row_uuid":"p2"}],
                 "conflicts":["p3"]}}''');

      final result = await transportOn(rec).push(const [one]);

      expect(result.accepted, {'p1'});
      expect(result.rejected, {'p2'});
      expect(result.conflicts, {'p3'});
    });
  });

  group('enrollment paths', () {
    setUp(() => SharedPreferences.setMockInitialValues({
          'sync_token': 'seat-token',
          'sync_business_uuid': 'biz',
          'sync_seat_uuid': 's1',
          'sync_role': 'owner',
        }));

    SyncEnrollmentRepositoryImpl repo(_Recorder rec) =>
        SyncEnrollmentRepositoryImpl(
          SyncApiClient(client: rec.client, baseUrl: _kBase),
          SyncCredentialStore(),
          const DeviceIdentityService(),
          LicenseLocalStorage(),
        );

    test('minting a join code posts to sync/join-tokens', () async {
      final rec = _Recorder();
      await repo(rec).mintJoinToken();
      expect(rec.only, 'POST $_kBase/sync/join-tokens');
    });

    test('a mint that returns no code fails instead of drawing a blank QR',
        () async {
      // The mint response's field names were never pinned by the backend, so an
      // unexpected spelling parses to an empty token. Rendered, that is a QR of
      // nothing and an empty line to type — the owner holds out a code that
      // cannot work and concludes the *other* phone is broken.
      final rec = _Recorder();
      final result = await repo(rec).mintJoinToken();

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure.message, contains('join token')),
        (token) => fail('an empty code must not be handed out: $token'),
      );
    });

    test('the registry, rename and revoke keep their seat-keyed paths', () async {
      // These three were always right — they are the only sync calls a real
      // phone had ever completed, which is exactly why the screen looked
      // healthy while nothing was replicating.
      var rec = _Recorder();
      await repo(rec).listDevices();
      expect(rec.only, 'GET $_kBase/sync/devices');

      rec = _Recorder();
      await repo(rec).renameDevice('seat-9', 'الكاشير');
      expect(rec.only, 'PATCH $_kBase/sync/devices/seat-9');

      rec = _Recorder();
      await repo(rec).revokeDevice('seat-9');
      expect(rec.only, 'DELETE $_kBase/sync/devices/seat-9');
    });
  });

  group('the bootstrap snapshot goes to the token that binds it', () {
    test('the seed endpoint is the join token sub-resource', () {
      expect(BootstrapService.seedEndpoint('JT-123'),
          'sync/join-tokens/JT-123/bootstrap');
    });

    test('it is derived from the token, never a fixed path', () {
      // The old constant (`sync/enroll/seed`) was the same string for every
      // invitation, so nothing but a body field tied a snapshot to the code the
      // joining phone would present.
      expect(BootstrapService.seedEndpoint('a'),
          isNot(BootstrapService.seedEndpoint('b')));
    });

    test('the path segment is the raw join token, not a uuid or a hash', () {
      // What evotech-core's own bug turned out to be, mirrored from our side so
      // it stays true if either end is reworked: the value in the URL is the
      // exact string `POST /sync/join-tokens` handed us and the joiner presents
      // to `/sync/enroll`. One identifier drives the whole enrollment chain.
      expect(BootstrapService.seedEndpoint('evojoin_abc123'),
          contains('evojoin_abc123'));
    });

    test('the hash rides as snapshot_sha256, never sha256', () {
      // The field the server validates. We sent `sha256` from the first cut and
      // no test could see it: the endpoint suite only ever asserted the URL,
      // and every other sync test drives an in-memory relay with no wire format
      // at all. It stayed invisible because their route 404'd before reaching
      // validation, so the 422 this would have caused was never reached.
      final fields = BootstrapService.seedFields(
        joinToken: 'JT-123',
        cursor: 7,
        sha256: 'a' * 64,
      );

      expect(fields['snapshot_sha256'], 'a' * 64);
      expect(fields.containsKey('sha256'), isFalse,
          reason: 'the old spelling is a 422, not a fallback');
      expect(fields['cursor'], '7');
      expect(fields['join_token'], 'JT-123');
    });

    test('cursor 0 is sent, not dropped as a falsy value', () {
      // A first device that has never pulled reports 0, and 0 is a real
      // position: omitting it would fail validation (`cursor` is required,
      // >= 0) on exactly the shop most likely to be adding its second phone.
      expect(
        BootstrapService.seedFields(
            joinToken: 'JT-123', cursor: 0, sha256: 'b' * 64)['cursor'],
        '0',
      );
    });
  });

  group('the base URL is the versioned root, not the app namespace', () {
    test('…/api/fawateer becomes …/api/v1', () {
      // Licensing is Profile A (`/api/fawateer`), sync is Profile B (`/api/v1`).
      // Getting this wrong produces the same silent 404 as a wrong path.
      final client = SyncApiClient();
      expect(client.baseUrl, endsWith('/api/v1'));
    });
  });
}
