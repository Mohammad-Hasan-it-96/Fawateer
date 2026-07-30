// Seeding a third device from the owner's shop (Plan 002, bootstrap).
//
// The whole point of this file is ONE test: a third device enrolling while a
// second device has a change the owner has not pulled. The happy path —
// enrol, restore, pull — passes under both the rule we shipped to the backend
// and the corrected one, which is exactly what makes it worthless as a guard.
// The backend asked for this case by name (2026-07-29 §1) after finding the
// bug in our own proposal, and it needs only two existing devices, so every
// 3- and 5-seat shop can hit it.
//
// It drives the REAL BootstrapService against three real databases and a shared
// relay, including the restore that swaps a database file and the reopen that
// stands in for the app restart. A test that reimplemented the ordering would
// only prove the test agrees with itself — and the ordering is the thing under
// test.
//
// Run: flutter test integration_test/bootstrap_test.dart -d <deviceId>
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:billing_app/core/database/app_database.dart';
import 'package:billing_app/core/error/failure.dart';
import 'package:billing_app/core/network/sync_api_client.dart';
import 'package:billing_app/features/backup/data/backup_engine.dart';
import 'package:billing_app/features/licensing/data/services/device_identity_service.dart';
import 'package:billing_app/features/sync/data/bootstrap_service.dart';
import 'package:billing_app/features/sync/data/snapshot_seeder.dart';
import 'package:billing_app/features/sync/data/sync_credential_store.dart';
import 'package:billing_app/features/sync/data/sync_state_store.dart';
import 'package:billing_app/features/sync/domain/entities/bootstrap_handoff.dart';
import 'package:billing_app/features/sync/domain/entities/enrollment_outcome.dart';
import 'package:billing_app/features/sync/domain/entities/join_token.dart';
import 'package:billing_app/features/sync/domain/entities/sync_seat_role.dart';
import 'package:billing_app/features/sync/domain/entities/sync_session.dart';
import 'package:billing_app/features/sync/domain/repositories/sync_enrollment_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'sync_relay.dart';

const _session = SyncSession(
  syncToken: 'owner-token',
  businessUuid: 'biz',
  seatUuid: 'seat',
  role: SyncSeatRole.owner,
  deviceAllowance: 3,
);

/// Stands in for the platform's private storage: whatever the owner uploads is
/// what the joiner downloads, byte for byte.
class _CourierApi implements SyncApiClient {
  Uint8List? stored;
  Map<String, String> fields = {};

  /// Corrupt the file in transit, to exercise the integrity guard.
  bool tamper = false;

  @override
  Future<Map<String, dynamic>> postFile(
    String endpoint,
    File file, {
    Map<String, String> fields = const {},
    String field = 'snapshot',
    String? token,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    // The upload must carry the OWNER's seat token, not the join token — the
    // join token is only the binding (2026-07-29 H1).
    expect(token, _session.syncToken);
    stored = await file.readAsBytes();
    this.fields = fields;
    return {'data': <String, dynamic>{}};
  }

  @override
  Future<List<int>> downloadBytes(String url,
      {Duration timeout = const Duration(minutes: 5)}) async {
    final bytes = Uint8List.fromList(stored!);
    if (tamper) bytes[bytes.length - 1] ^= 0xFF;
    return bytes;
  }

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName} not needed');
}

class _FakeEnrollment implements SyncEnrollmentRepository {
  @override
  Future<Either<Failure, JoinToken>> mintJoinToken() async => Right(JoinToken(
        token: 'JOIN-CODE',
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      ));

  @override
  Future<Either<Failure, EnrollmentOutcome>> establishAsOwner(
          {String? pushToken}) async =>
      const Right(EnrollmentOutcome(
          session: _session, bootstrap: BootstrapHandoff(cursor: 0)));

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName} not needed');
}

class _StubCredentials implements SyncCredentialStore {
  @override
  Future<SyncSession?> load() async => _session;

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName} not needed');
}

class _StubIdentity implements DeviceIdentityService {
  @override
  Future<String> getDeviceId() async => 'device-under-test';

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName} not needed');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Both of these are pinned rather than left to the platform, so the test is
  // hermetic and runs the same on a device and on the host engine — where the
  // path_provider plugin is not registered at all and `createSnapshot` would
  // otherwise fail before reaching anything this test is about.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => Directory.systemTemp.path,
  );

  // The snapshot's manifest records the app version; pinning it keeps the test
  // from depending on whatever build it happens to run against.
  PackageInfo.setMockInitialValues(
    appName: 'Fawateer',
    packageName: 'com.mohamad.hasan.it.fawateer',
    version: '1.0.1',
    buildNumber: '1',
    buildSignature: '',
  );

  late SyncRelay relay;
  late TestDevice owner;
  late TestDevice member;
  late _CourierApi api;
  final joined = <TestDevice>[];

  BootstrapService serviceFor(TestDevice d) => BootstrapService(
        enrollment: _FakeEnrollment(),
        engine: d.engine,
        state: SyncStateStore(d.db.settingsDao),
        backup: BackupEngine(d.db, _StubIdentity()),
        seeder: SnapshotSeeder(d.db),
        api: api,
        credentials: _StubCredentials(),
      );

  setUp(() async {
    relay = SyncRelay();
    api = _CourierApi();
    owner = await TestDevice.create('owner', 'nodeOOOOOOOOOOOO', relay);
    member = await TestDevice.create('member', 'nodeMMMMMMMMMMMM', relay);
    joined.clear();
  });

  tearDown(() async {
    for (final d in [owner, member, ...joined]) {
      await d.dispose();
    }
  });

  Future<void> addProduct(TestDevice d, String id, String name,
      {double qty = 0}) async {
    final stamp = await d.clock.stamp();
    await d.db.productsDao.createProduct(ProductsCompanion.insert(
      id: id,
      name: name,
      price: 5000,
      updatedAt: Value(stamp.hlc),
      originDevice: Value(stamp.device),
    ));
    if (qty != 0) {
      await d.db.stockDao.setOnHand(
        productId: id,
        target: qty,
        movementId: 'open-$id-${d.name}',
        reason: 'openingBalance',
        now: 1000,
        stamp: await d.clock.stamp(),
      );
    }
  }

  Future<void> sell(TestDevice d, String invoiceId) async {
    final stamp = await d.clock.stamp();
    await d.db.salesDao.insertInvoiceWithItems(
      stamp: stamp,
      invoice: SalesInvoicesCompanion.insert(
        id: invoiceId,
        createdAt: 1000,
        totalAmount: 5000,
        updatedAt: Value(stamp.hlc),
        originDevice: Value(stamp.device),
      ),
      items: [
        SalesItemsCompanion.insert(
          invoiceId: invoiceId,
          productId: 'p1',
          productName: 'رز',
          price: 5000,
          quantity: 1,
          uuid: Value('$invoiceId-0'),
          updatedAt: Value(stamp.hlc),
          originDevice: Value(stamp.device),
        ),
      ],
    );
  }

  /// Enrol a new device on the seed the owner just uploaded, then reopen it —
  /// which is exactly what the app does after the restore kills it.
  Future<TestDevice> joinFrom(BootstrapHandoff handoff, String? sha,
      {String node = 'nodeNNNNNNNNNNNN'}) async {
    final fresh = await TestDevice.create('new', node, relay);
    final result =
        await serviceFor(fresh).adopt(handoff, expectedSha256: sha);
    expect(result.getOrElse((_) => BootstrapResult.cursorOnly),
        BootstrapResult.restartRequired,
        reason: 'a seeded device must be told to restart');

    final restarted = await TestDevice.open('new', node, relay, fresh.file);
    joined.add(restarted);
    return restarted;
  }

  /// The handoff the server would compose from what the owner uploaded.
  BootstrapHandoff handoffFromUpload() => BootstrapHandoff(
        cursor: int.parse(api.fields['cursor']!),
        snapshotUrl: 'https://storage.example/seed',
        snapshotSha256: api.fields['sha256'],
      );

  Future<Set<String>> invoicesOn(TestDevice d) async =>
      (await d.db.salesDao.getAllInvoices()).map((i) => i.id).toSet();

  group('the distinguishing case', () {
    // Owner O and member M are an established two-till shop. M sells something
    // and pushes it. O has NOT pulled it. O now enrols a third phone.
    Future<void> shopWithAnUnpulledSale() async {
      await addProduct(owner, 'p1', 'رز', qty: 50);
      await owner.engine.sync();
      await member.engine.sync();

      await sell(member, 'invM');
      await member.engine.sync();

      // Deliberately no owner.engine.sync() here — that absence IS the test.
      expect(await invoicesOn(owner), isEmpty,
          reason: "the owner must not have seen the member's sale yet");
    }

    test("a third phone gets the sale the owner had not pulled", () async {
      await shopWithAnUnpulledSale();

      final invite = await serviceFor(owner).prepareInvite();
      expect(invite.isRight(), isTrue,
          reason: 'preparing the seed must succeed: ${invite.getLeft()}');
      final sha = invite.getOrElse((_) => throw StateError('checked'))
          .snapshotSha256;

      final fresh = await joinFrom(handoffFromUpload(), sha);
      await fresh.engine.sync();

      // Under the superseded rule this row is in neither the snapshot nor the
      // range the new phone pulls. It is lost with no error, no retry, and
      // nothing to observe — a sale that simply never existed on one till.
      expect(await invoicesOn(fresh), contains('invM'),
          reason: "the member's sale must survive a third phone joining");
    });

    test('the superseded rule loses it — why the case above is the test',
        () async {
      await shopWithAnUnpulledSale();

      // Our original proposal, which the backend adopted verbatim before
      // finding the hole: push everything, snapshot, then ask the SERVER where
      // it is up to. The owner has nothing pending, so "push everything" is a
      // no-op and the snapshot simply misses the member's sale.
      final (file, manifest) = await BackupEngine(owner.db, _StubIdentity())
          .createSnapshot();
      api.stored = await file.readAsBytes();
      final serverHead = relay.head;
      await file.delete();

      final fresh = await joinFrom(
        BootstrapHandoff(
          cursor: serverHead,
          snapshotUrl: 'https://storage.example/seed',
          snapshotSha256: manifest.sha256,
        ),
        manifest.sha256,
      );
      await fresh.engine.sync();

      expect(await invoicesOn(fresh), isNot(contains('invM')),
          reason: 'if this ever passes, the two tests are no longer '
              'distinguishing and the guard is gone');
    });
  });

  group('the seed itself', () {
    test('the shop arrives even though none of it was ever pushed', () async {
      // Everything here predates sync (updated_at = ''), so the replication log
      // has never carried it and never will. This is the entire reason the
      // bootstrap exists.
      await addProduct(owner, 'p1', 'رز', qty: 50);
      await owner.db.customStatement(
          "UPDATE products SET updated_at = '', origin_device = ''");

      final invite = await serviceFor(owner).prepareInvite();
      final fresh = await joinFrom(handoffFromUpload(),
          invite.getOrElse((_) => throw StateError('checked')).snapshotSha256);

      expect(await fresh.db.productsDao.getById('p1'), isNotNull,
          reason: 'a phone that joins an existing shop must not find it empty');
    });

    test('the new phone starts from the owner position, not from zero',
        () async {
      await addProduct(owner, 'p1', 'رز');
      await owner.engine.sync();

      final invite = await serviceFor(owner).prepareInvite();
      final fresh = await joinFrom(handoffFromUpload(),
          invite.getOrElse((_) => throw StateError('checked')).snapshotSha256);

      expect(await SyncStateStore(fresh.db.settingsDao).pullCursor(),
          int.parse(api.fields['cursor']!),
          reason: "the owner's cursor is written INTO the snapshot — after the "
              'swap there is no database left to write it to');
    });

    test('the new phone does not push the whole shop straight back', () async {
      await addProduct(owner, 'p1', 'رز', qty: 50);
      await owner.engine.sync();
      final before = relay.log.length;

      final invite = await serviceFor(owner).prepareInvite();
      final fresh = await joinFrom(handoffFromUpload(),
          invite.getOrElse((_) => throw StateError('checked')).snapshotSha256);
      final outcome = await fresh.engine.sync();

      expect(outcome.pushed, 0,
          reason: 'the snapshot came FROM the server; sending it back is a '
              'round trip of data it demonstrably has');
      expect(relay.log.length, before);
    });

    test("the owner's Drive account does not travel with the shop", () async {
      await owner.db.settingsDao
          .setValue('backup_account_email', 'owner@example.com');
      await addProduct(owner, 'p1', 'رز');

      final invite = await serviceFor(owner).prepareInvite();
      final fresh = await joinFrom(handoffFromUpload(),
          invite.getOrElse((_) => throw StateError('checked')).snapshotSha256);

      expect(await fresh.db.settingsDao.getValue('backup_account_email'), isNull,
          reason: 'a Drive account this phone cannot sign into, shown as '
              'connected, is a claim it has no way to question');
    });
  });

  group('guards', () {
    test('a snapshot corrupted in transit is refused before the swap',
        () async {
      await addProduct(owner, 'p1', 'رز');
      final invite = await serviceFor(owner).prepareInvite();
      final sha = invite
          .getOrElse((_) => throw StateError('checked'))
          .snapshotSha256;

      api.tamper = true;
      final fresh = await TestDevice.create('new', 'nodeNNNNNNNNNNNN', relay);
      joined.add(fresh);
      final result =
          await serviceFor(fresh).adopt(handoffFromUpload(), expectedSha256: sha);

      expect(result.getLeft().toNullable(),
          const IncompatibleFailure('checksum_mismatch'));
      // The live database is untouched — failing here is still free.
      expect(await fresh.db.productsDao.getAllProducts(), isEmpty);
    });

    test('a snapshot from a newer build is refused, not migrated backwards',
        () async {
      await addProduct(owner, 'p1', 'رز');
      await serviceFor(owner).prepareInvite();

      final fresh = await TestDevice.create('new', 'nodeNNNNNNNNNNNN', relay);
      joined.add(fresh);
      // Claim the file was written by a future schema. Drift migrations are
      // forward-only, so running this backwards corrupts silently.
      final bumped = File('${fresh.file.path}.future');
      await bumped.writeAsBytes(api.stored!);
      final probe = AppDatabase.forTesting(NativeDatabase(bumped));
      await probe.customStatement(
          'PRAGMA user_version = ${fresh.db.schemaVersion + 1}');
      await probe.close();
      api.stored = await bumped.readAsBytes();
      await bumped.delete();

      // Hashed after the bump, so this test fails on the *version* guard rather
      // than tripping the integrity one first and proving nothing.
      final result = await serviceFor(fresh).adopt(handoffFromUpload(),
          expectedSha256: sha256.convert(api.stored!).toString());

      expect(result.getLeft().toNullable(),
          const IncompatibleFailure('schema_too_new'));
    });

    test('a seedless handoff adopts a cursor and leaves the database alone',
        () async {
      // The shop's first device: establishing a business, not joining one.
      final result = await serviceFor(owner)
          .adopt(const BootstrapHandoff(cursor: 7));

      expect(result.getOrElse((_) => BootstrapResult.restartRequired),
          BootstrapResult.cursorOnly);
      expect(await SyncStateStore(owner.db.settingsDao).pullCursor(), 7);
    });
  });
}
