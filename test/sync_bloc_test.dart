// The multi-device screen's state machine (Plan 002).
//
// Hand-written fakes, no Drift and no plugins — the codebase rule for BLoC
// tests. What is being checked is the decisions the screen makes: does an
// unenrolled device get the pitch rather than a flash of the wrong screen, is a
// typed error carried out untranslated, does a one-shot message fire exactly
// once, and is a join code never left on screen after it has been used.
import 'package:billing_app/core/database/daos/settings_dao.dart';
import 'package:billing_app/core/database/daos/sync_dao.dart';
import 'package:billing_app/core/error/failure.dart';
import 'package:billing_app/features/sync/data/bootstrap_service.dart';
import 'package:billing_app/features/sync/data/sync_credential_store.dart';
import 'package:billing_app/features/sync/data/sync_engine.dart';
import 'package:billing_app/features/sync/data/sync_scheduler.dart';
import 'package:billing_app/features/sync/data/sync_state_store.dart';
import 'package:billing_app/features/sync/domain/entities/bootstrap_handoff.dart';
import 'package:billing_app/features/sync/domain/entities/enrollment_outcome.dart';
import 'package:billing_app/features/sync/domain/entities/join_invite.dart';
import 'package:billing_app/features/sync/domain/entities/join_token.dart';
import 'package:billing_app/features/sync/domain/entities/sync_device.dart';
import 'package:billing_app/features/sync/domain/entities/sync_device_registry.dart';
import 'package:billing_app/features/sync/domain/entities/sync_outcome.dart';
import 'package:billing_app/features/sync/domain/entities/sync_seat_role.dart';
import 'package:billing_app/features/sync/domain/entities/sync_session.dart';
import 'package:billing_app/features/sync/domain/repositories/sync_enrollment_repository.dart';
import 'package:billing_app/features/sync/domain/sync_error.dart';
import 'package:billing_app/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

const _ownerSession = SyncSession(
  syncToken: 'tok',
  businessUuid: 'biz',
  seatUuid: 'seat',
  role: SyncSeatRole.owner,
  deviceAllowance: 3,
);

const _memberSession = SyncSession(
  syncToken: 'tok',
  businessUuid: 'biz',
  seatUuid: 'seat2',
  role: SyncSeatRole.member,
  deviceAllowance: 3,
);

class _FakeEnrollment implements SyncEnrollmentRepository {
  SyncSession? session;
  Failure? failure;
  JoinToken? token;
  int leaveCalls = 0;
  String? lastJoinToken;

  List<SyncDevice> devices = const [];
  int? allowance = 3;
  Failure? devicesFailure;
  Failure? revokeFailure;
  int listCalls = 0;
  final List<String> revoked = [];

  EnrollmentOutcome _outcome(SyncSession s) => EnrollmentOutcome(
        session: s,
        bootstrap: const BootstrapHandoff(cursor: 0),
      );

  @override
  Future<Either<Failure, EnrollmentOutcome>> establishAsOwner({String? pushToken}) async {
    final f = failure;
    if (f != null) return Left(f);
    session = _ownerSession;
    return Right(_outcome(_ownerSession));
  }

  @override
  Future<Either<Failure, EnrollmentOutcome>> joinBusiness(String joinToken,
      {String? pushToken}) async {
    lastJoinToken = joinToken;
    final f = failure;
    if (f != null) return Left(f);
    session = _memberSession;
    return Right(_outcome(_memberSession));
  }

  @override
  Future<Either<Failure, JoinToken>> mintJoinToken() async {
    final f = failure;
    if (f != null) return Left(f);
    return Right(token!);
  }

  @override
  Future<Either<Failure, SyncDeviceRegistry>> listDevices() async {
    listCalls++;
    final f = devicesFailure;
    if (f != null) return Left(f);
    return Right(SyncDeviceRegistry(devices: devices, allowance: allowance));
  }

  @override
  Future<Either<Failure, Unit>> revokeDevice(String seatUuid) async {
    revoked.add(seatUuid);
    final f = revokeFailure;
    if (f != null) return Left(f);
    devices = devices.where((d) => d.uuid != seatUuid).toList();
    return const Right(unit);
  }

  @override
  Future<SyncSession?> currentSession() async => session;

  @override
  Future<void> leave() async {
    leaveCalls++;
    session = null;
  }
}

class _FakeSettings implements SettingsDao {
  final Map<String, String> store = {};

  @override
  Future<String?> getValue(String key) async => store[key];

  @override
  Future<void> setValue(String key, String value) async => store[key] = value;

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName} not needed');
}

class _StubEngine implements SyncEngine {
  SyncOutcome result = const SyncOutcome();

  @override
  Future<SyncOutcome> sync() async => result;

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName} not needed');
}

/// Stands in for the real bootstrap, which needs a database, a vacuum and a
/// network. It defers to [_FakeEnrollment] for the mint so the existing
/// join-code tests keep exercising the BLoC's own decisions.
class _StubBootstrap implements BootstrapService {
  _StubBootstrap(this.repository);

  final _FakeEnrollment repository;

  /// What `adopt` reports back. The default is the seedless case — a first
  /// device establishing a business.
  Either<Failure, BootstrapResult> adoptResult =
      const Right(BootstrapResult.cursorOnly);
  int adoptCalls = 0;
  String? lastExpectedSha;
  String? snapshotSha = 'sha-of-the-shop';

  @override
  Future<Either<Failure, JoinInvite>> prepareInvite({
    void Function(BootstrapStep)? onStep,
  }) async {
    onStep?.call(BootstrapStep.syncing);
    final f = repository.failure;
    if (f != null) return Left(f);
    onStep?.call(BootstrapStep.uploading);
    return Right(
        JoinInvite(token: repository.token!, snapshotSha256: snapshotSha));
  }

  @override
  Future<Either<Failure, BootstrapResult>> adopt(
    BootstrapHandoff handoff, {
    String? expectedSha256,
  }) async {
    adoptCalls++;
    lastExpectedSha = expectedSha256;
    return adoptResult;
  }

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName} not needed');
}

class _StubCredentials implements SyncCredentialStore {
  SyncSession? session = _ownerSession;

  @override
  Future<SyncSession?> load() async => session;

  /// Real, not a `noSuchMethod` throw: the scheduler calls this when a pass
  /// comes back `DEVICE_REVOKED`, and a throwing stub would be swallowed by the
  /// scheduler's own catch — turning a revocation into a silent no-op the test
  /// could never see.
  @override
  Future<void> clear() async => session = null;

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName} not needed');
}

void main() {
  // SyncBloc starts the scheduler after a successful enrollment, and the
  // scheduler registers a lifecycle observer — which needs a binding even
  // though nothing here builds a widget.
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeEnrollment repository;
  late _FakeSettings settings;
  late _StubEngine engine;
  late SyncScheduler scheduler;
  late _StubBootstrap bootstrap;

  SyncBloc build() {
    settings = _FakeSettings();
    engine = _StubEngine();
    bootstrap = _StubBootstrap(repository);
    scheduler = SyncScheduler(
      engine: engine,
      credentials: _StubCredentials(),
      dao: _NoopSyncDao(),
    );
    return SyncBloc(
      repository: repository,
      scheduler: scheduler,
      state: SyncStateStore(settings),
      bootstrap: bootstrap,
    );
  }

  setUp(() => repository = _FakeEnrollment());

  group('loading', () {
    test('an unenrolled device reports loaded with no session', () async {
      final bloc = build();
      bloc.add(const LoadSyncStatus());
      await bloc.stream.firstWhere((s) => s.loaded);

      // `loaded` is separate from `session != null` precisely so the page can
      // hold a spinner instead of flashing the "turn this on" pitch at a device
      // that is already enrolled.
      expect(bloc.state.loaded, isTrue);
      expect(bloc.state.isEnrolled, isFalse);
      await bloc.close();
    });

    test('an enrolled device reports its seat and role', () async {
      repository.session = _ownerSession;
      final bloc = build();
      bloc.add(const LoadSyncStatus());
      await bloc.stream.firstWhere((s) => s.loaded);

      expect(bloc.state.isEnrolled, isTrue);
      expect(bloc.state.isOwner, isTrue);
      expect(bloc.state.session?.deviceAllowance, 3);
      await bloc.close();
    });
  });

  group('enrolling', () {
    test('enabling as owner stores the seat and reports success', () async {
      final bloc = build();
      bloc.add(const EnableSyncAsOwner());
      await bloc.stream.firstWhere((s) => s.message != null);

      expect(bloc.state.isOwner, isTrue);
      expect(bloc.state.message, SyncMessage.enabled);
      expect(bloc.state.busy, isFalse);
      await bloc.close();
    });

    test('a server refusal is carried out as a TYPED error', () async {
      repository.failure =
          const SyncFailure(SyncError.allowanceExceeded, 'at cap');
      final bloc = build();
      bloc.add(const EnableSyncAsOwner());
      await bloc.stream.firstWhere((s) => s.error != null);

      // The app's rule: no user-facing English in a BLoC. "You've used all your
      // phones" has to come from ARB, and the difference between this and a
      // generic failure is the difference between the owner upgrading their
      // plan and filing a support ticket.
      expect(bloc.state.error, SyncError.allowanceExceeded);
      expect(bloc.state.isEnrolled, isFalse);
      await bloc.close();
    });

    test('an offline failure maps to the retryable error', () async {
      repository.failure = const NetworkFailure('no route');
      final bloc = build();
      bloc.add(const EnableSyncAsOwner());
      await bloc.stream.firstWhere((s) => s.error != null);

      expect(bloc.state.error, SyncError.offline);
      await bloc.close();
    });

    test('a blank code is refused without a round trip', () async {
      final bloc = build();
      bloc.add(const JoinWithToken('   '));
      await bloc.stream.firstWhere((s) => s.error != null);

      expect(bloc.state.error, SyncError.invalidJoinToken);
      expect(repository.lastJoinToken, isNull,
          reason: 'nothing should have been sent');
      await bloc.close();
    });

    test('a scanned code is trimmed before it is redeemed', () async {
      final bloc = build();
      bloc.add(const JoinWithToken('  ABC-123 '));
      await bloc.stream.firstWhere((s) => s.message != null);

      // A scanner or a paste can easily carry whitespace, and the server
      // compares the token exactly.
      expect(repository.lastJoinToken, 'ABC-123');
      expect(bloc.state.message, SyncMessage.joined);
      await bloc.close();
    });
  });

  group('the join code', () {
    test('is published for display', () async {
      repository.session = _ownerSession;
      repository.token = JoinToken(
        token: 'JOIN-1',
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      );
      final bloc = build();
      bloc.add(const MintJoinTokenRequested());
      await bloc.stream.firstWhere((s) => s.invite != null);

      expect(bloc.state.invite?.token.token, 'JOIN-1');
      // The invitation carries the snapshot's fingerprint, not just the code:
      // the joining device checks the file against the OWNER's hash, never
      // against the one the server hands back with its own delivery.
      expect(bloc.state.invite?.snapshotSha256, 'sha-of-the-shop');
      await bloc.close();
    });

    test('is cleared on dismiss, and never lingers after a failed re-mint',
        () async {
      repository.session = _ownerSession;
      repository.token = JoinToken(
        token: 'JOIN-1',
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      );
      final bloc = build();
      bloc.add(const MintJoinTokenRequested());
      await bloc.stream.firstWhere((s) => s.invite != null);

      bloc.add(const DismissJoinToken());
      await bloc.stream.firstWhere((s) => s.invite == null);
      expect(bloc.state.invite, isNull);

      // Re-mint fails: the OLD code must not still be on screen. It is
      // single-use and probably already spent, and an owner re-showing a dead
      // code will blame the other phone.
      repository.failure = const SyncFailure(SyncError.server, 'boom');
      bloc.add(const MintJoinTokenRequested());
      await bloc.stream.firstWhere((s) => s.error != null);
      expect(bloc.state.invite, isNull);
      await bloc.close();
    });
  });

  group('bootstrap', () {
    test('a scanned invitation hands the owner hash to the seed check',
        () async {
      final bloc = build();
      bloc.add(const JoinWithToken('FW1:ABC-123:deadbeef'));
      await bloc.stream.firstWhere((s) => s.message != null);

      // The token goes to the server; the hash never does — it is the one thing
      // the joiner must NOT take the server's word on.
      expect(repository.lastJoinToken, 'ABC-123');
      expect(bootstrap.lastExpectedSha, 'deadbeef');
      await bloc.close();
    });

    test('a typed code joins with no hash rather than refusing', () async {
      final bloc = build();
      bloc.add(const JoinWithToken('ABC-123'));
      await bloc.stream.firstWhere((s) => s.message != null);

      // A cracked lens is common in this trade, so the typed path must work.
      // It falls back to the server's declared hash — a narrower guarantee, and
      // the reason the UI nudges towards scanning.
      expect(repository.lastJoinToken, 'ABC-123');
      expect(bootstrap.lastExpectedSha, isNull);
      await bloc.close();
    });

    test('a restored snapshot demands a restart and does NOT start syncing',
        () async {
      final bloc = build();
      bootstrap.adoptResult = const Right(BootstrapResult.restartRequired);
      bloc.add(const JoinWithToken('CODE'));
      await bloc.stream.firstWhere((s) => s.restartRequired);

      // SQLite is closed at this point. Starting the scheduler would have it
      // throw on its very first read.
      expect(bloc.state.restartRequired, isTrue);
      expect(bloc.state.isEnrolled, isTrue);
      await bloc.close();
    });

    test('a seed that fails hands the seat back instead of half-joining',
        () async {
      final bloc = build();
      bootstrap.adoptResult =
          const Left(IncompatibleFailure('checksum_mismatch'));
      bloc.add(const JoinWithToken('CODE'));
      await bloc.stream.firstWhere((s) => s.error != null);

      // Otherwise the device sits enrolled and empty, holding a seat, with the
      // single-use code already spent and no way to ask for another.
      expect(bloc.state.isEnrolled, isFalse);
      expect(repository.leaveCalls, 1);
      await bloc.close();
    });

    test('a broken restore keeps the seat — only a restart can help', () async {
      final bloc = build();
      bootstrap.adoptResult = const Left(RestoreIncompleteFailure('disk full'));
      bloc.add(const JoinWithToken('CODE'));
      await bloc.stream.firstWhere((s) => s.restartRequired);

      // Unlike the case above, dropping the seat here would be pretending we
      // can tidy up. The database connection is gone; nothing can be undone.
      expect(repository.leaveCalls, 0);
      await bloc.close();
    });

    test('establishing a business adopts a cursor and never a snapshot',
        () async {
      final bloc = build();
      bloc.add(const EnableSyncAsOwner());
      await bloc.stream.firstWhere((s) => s.message != null);

      expect(bootstrap.adoptCalls, 1);
      expect(bloc.state.restartRequired, isFalse,
          reason: 'the first device has nothing to restore');
      await bloc.close();
    });
  });

  group('sync now', () {
    test('reports the counts and the time', () async {
      repository.session = _ownerSession;
      final bloc = build();
      engine.result = const SyncOutcome(pushed: 2, pulled: 5);
      // The engine stamps this; the BLoC's job is to re-read it afterwards so
      // the "last sync" line is not stale by exactly one pass.
      settings.store[SyncStateStore.kLastSyncAt] =
          DateTime(2026, 7, 29, 14, 5).millisecondsSinceEpoch.toString();

      bloc.add(const SyncNowRequested());
      await bloc.stream.firstWhere((s) => s.outcome != null);

      expect(bloc.state.outcome?.pushed, 2);
      expect(bloc.state.outcome?.pulled, 5);
      expect(bloc.state.lastSyncAt, DateTime(2026, 7, 29, 14, 5));
      await bloc.close();
    });

    test('a pass that moved nothing is still a success', () async {
      repository.session = _ownerSession;
      final bloc = build();
      engine.result = const SyncOutcome();
      bloc.add(const SyncNowRequested());
      await bloc.stream.firstWhere((s) => s.outcome != null);

      // "Already up to date" is a real answer. Reporting it as an error, or as
      // nothing at all, is how a working button gets reported as broken.
      expect(bloc.state.error, isNull);
      expect(bloc.state.outcome?.isSuccess, isTrue);
      expect(bloc.state.outcome?.didWork, isFalse);
      await bloc.close();
    });

    test('a failed pass surfaces its reason', () async {
      repository.session = _ownerSession;
      final bloc = build();
      engine.result = const SyncOutcome(error: SyncError.offline);
      bloc.add(const SyncNowRequested());
      await bloc.stream.firstWhere((s) => s.error != null);

      expect(bloc.state.error, SyncError.offline);
      await bloc.close();
    });
  });

  group('the device registry', () {
    const owner = SyncDevice(uuid: 'seat', role: SyncSeatRole.owner);
    const other = SyncDevice(uuid: 'seat-9', role: SyncSeatRole.member);

    test('loads for the owner, and never for a linked phone', () async {
      repository.session = _memberSession;
      repository.devices = const [owner, other];
      final bloc = build();
      bloc.add(const LoadSyncStatus());
      await bloc.stream.firstWhere((s) => s.loaded);
      // Let a stray fetch land if one were dispatched.
      await Future<void>.delayed(Duration.zero);

      // The endpoint is owner-only; a member asking would be a guaranteed
      // refusal, and the error would land on a screen the member can do nothing
      // about.
      expect(repository.listCalls, 0);
      await bloc.close();
    });

    test('the seat renders before the network answers', () async {
      repository.session = _ownerSession;
      repository.devices = const [owner, other];
      final bloc = build();
      bloc.add(const LoadSyncStatus());

      final first = await bloc.stream.firstWhere((s) => s.loaded);
      // The registry needs the network; the rest of the screen does not. If the
      // fetch were awaited inside the load, an offline owner would sit on a
      // spinner until it timed out.
      expect(first.isEnrolled, isTrue);
      expect(first.devices, isEmpty);

      await bloc.stream.firstWhere((s) => s.devices.isNotEmpty);
      expect(bloc.state.devices.length, 2);
      await bloc.close();
    });

    test('the current seat is flagged and is not revocable', () async {
      repository.session = _ownerSession;
      repository.devices = const [
        SyncDevice(uuid: 'seat', role: SyncSeatRole.owner, isCurrent: true),
        other,
      ];
      final bloc = build();
      bloc.add(const LoadSyncStatus());
      await bloc.stream.firstWhere((s) => s.devices.isNotEmpty);

      // Two protections in one row: the owner seat is refused server-side
      // (2026-07-29 R1), and a phone revoking itself is never what was meant.
      expect(bloc.state.devices.first.isRevocable, isFalse);
      expect(bloc.state.devices.last.isRevocable, isTrue);
      await bloc.close();
    });

    test('a failed fetch does NOT become a snackbar over the screen', () async {
      repository.session = _ownerSession;
      repository.devicesFailure = const NetworkFailure('no route');
      final bloc = build();
      bloc.add(const LoadSyncStatus());
      await bloc.stream.firstWhere((s) => s.devicesError != null);

      // Nobody asked for this fetch. Routing it through `error` would throw a
      // red snackbar at an owner who merely opened the page — and would also
      // clear whatever the last real action had to say.
      expect(bloc.state.devicesError, SyncError.offline);
      expect(bloc.state.error, isNull);
      expect(bloc.state.isEnrolled, isTrue, reason: 'the rest of the page works');
      await bloc.close();
    });

    test('revoking drops the row immediately and re-reads the list', () async {
      repository.session = _ownerSession;
      repository.devices = const [owner, other];
      final bloc = build();
      bloc.add(const LoadSyncStatus());
      await bloc.stream.firstWhere((s) => s.devices.isNotEmpty);
      final listsBefore = repository.listCalls;

      bloc.add(const RevokeDeviceRequested('seat-9'));
      await bloc.stream
          .firstWhere((s) => s.message == SyncMessage.deviceRevoked);

      expect(repository.revoked, ['seat-9']);
      // Dropped locally rather than waiting on the re-read: the owner just
      // watched themselves remove it, and a row that lingers for a round trip
      // reads as the button not working.
      expect(bloc.state.devices.map((d) => d.uuid), ['seat']);
      expect(bloc.state.revoking, isNull);

      await bloc.stream.firstWhere((s) => !s.devicesLoading && s.loaded);
      expect(repository.listCalls, greaterThan(listsBefore),
          reason: 'the server is the authority on what a freed seat changed');
      await bloc.close();
    });

    test('a refused revoke keeps the row and reports the reason', () async {
      repository.session = _ownerSession;
      repository.devices = const [owner, other];
      repository.revokeFailure =
          const SyncFailure(SyncError.ownerOnly, 'not the owner');
      final bloc = build();
      bloc.add(const LoadSyncStatus());
      await bloc.stream.firstWhere((s) => s.devices.isNotEmpty);

      bloc.add(const RevokeDeviceRequested('seat-9'));
      await bloc.stream.firstWhere((s) => s.error != null);

      // The optimistic removal must not survive a refusal — a phone that is
      // still enrolled but missing from the list is one the owner cannot revoke
      // again without reopening the screen.
      expect(bloc.state.devices.map((d) => d.uuid), ['seat', 'seat-9']);
      expect(bloc.state.error, SyncError.ownerOnly);
      expect(bloc.state.revoking, isNull);
      await bloc.close();
    });

    test('a revoked device drops its own seat when it next syncs', () async {
      repository.session = _memberSession;
      final bloc = build();
      engine.result = const SyncOutcome(error: SyncError.deviceRevoked);
      bloc.add(const SyncNowRequested());
      await bloc.stream.firstWhere((s) => !s.isEnrolled && s.loaded);

      // The scheduler has already dropped the dead credential. Leaving the
      // screen on "Sync now" would have the shopkeeper tapping it to the same
      // red message forever; the pitch is both true and the way back in.
      expect(bloc.state.isEnrolled, isFalse);
      expect(bloc.state.error, SyncError.deviceRevoked);
      await bloc.close();
    });
  });

  group('the allowance', () {
    const owner = SyncDevice(uuid: 'seat', role: SyncSeatRole.owner);
    const m1 = SyncDevice(uuid: 's1', role: SyncSeatRole.member);
    const m2 = SyncDevice(uuid: 's2', role: SyncSeatRole.member);

    test('an unread registry is never at cap', () async {
      repository.session = _ownerSession;
      repository.devicesFailure = const NetworkFailure('no route');
      final bloc = build();
      bloc.add(const LoadSyncStatus());
      await bloc.stream.firstWhere((s) => s.devicesError != null);

      // The cached allowance is 3 and the list is empty — but empty here means
      // "we were not told", not "no phones". A gate that fires on missing
      // information locks an owner out of the plan they are paying for.
      expect(bloc.state.registry, isNull);
      expect(bloc.state.isAtCap, isFalse);
      expect(bloc.state.allowance, 3, reason: 'the cached limit still shows');
      await bloc.close();
    });

    test('a full registry is at cap', () async {
      repository.session = _ownerSession;
      repository.devices = const [owner, m1, m2];
      final bloc = build();
      bloc.add(const LoadSyncStatus());
      await bloc.stream.firstWhere((s) => s.devices.isNotEmpty);

      expect(bloc.state.isAtCap, isTrue);
      await bloc.close();
    });

    test('the server\'s allowance beats the one cached at enrollment', () async {
      repository.session = _ownerSession; // cached 3, from enrollment day
      repository.allowance = 5; // the owner has since upgraded
      repository.devices = const [owner, m1, m2];
      final bloc = build();
      bloc.add(const LoadSyncStatus());
      await bloc.stream.firstWhere((s) => s.devices.isNotEmpty);

      // device_allowance lives on the business row and is what a plan upgrade
      // changes. An owner who has just paid for five seats being told they have
      // three — and being blocked at three — is the failure this prevents.
      expect(bloc.state.allowance, 5);
      expect(bloc.state.isAtCap, isFalse);
      await bloc.close();
    });

    test('an unstated allowance gates nothing', () async {
      repository.session = _ownerSession;
      repository.allowance = null;
      repository.devices = const [owner, m1, m2];
      final bloc = build();
      bloc.add(const LoadSyncStatus());
      await bloc.stream.firstWhere((s) => s.devices.isNotEmpty);

      // Falls back to the cached 3, which the three seats do fill — but the
      // point is that it degrades to the cache rather than to zero. A null
      // allowance read as 0 would lock every owner out on the first response
      // that omitted the field.
      expect(bloc.state.allowance, 3);
      await bloc.close();
    });

    test('revoking a seat frees the cap immediately', () async {
      repository.session = _ownerSession;
      repository.devices = const [owner, m1, m2];
      final bloc = build();
      bloc.add(const LoadSyncStatus());
      await bloc.stream.firstWhere((s) => s.isAtCap);

      bloc.add(const RevokeDeviceRequested('s2'));
      await bloc.stream.firstWhere((s) => !s.isAtCap);

      // "Remove one to add another" has to be true the moment they do it —
      // otherwise the owner removes a phone, finds Add still disabled, and
      // concludes the removal did not work.
      expect(bloc.state.devices.length, 2);
      expect(bloc.state.isAtCap, isFalse);
      await bloc.close();
    });
  });

  group('leaving', () {
    test('clears the session locally and says so', () async {
      repository.session = _ownerSession;
      final bloc = build();
      bloc.add(const LeaveSyncRequested());
      await bloc.stream.firstWhere((s) => s.message == SyncMessage.left);

      expect(bloc.state.isEnrolled, isFalse);
      expect(repository.leaveCalls, 1);
      await bloc.close();
    });
  });

  test('feedback is one-shot', () async {
    final bloc = build();
    bloc.add(const EnableSyncAsOwner());
    await bloc.stream.firstWhere((s) => s.message != null);

    bloc.add(const ClearSyncFeedback());
    await bloc.stream.firstWhere((s) => s.message == null);

    // Without an explicit clear the snackbar re-fires on the next unrelated
    // rebuild — "sync is on" appearing again every time the page redraws.
    expect(bloc.state.message, isNull);
    expect(bloc.state.error, isNull);
    expect(bloc.state.isEnrolled, isTrue, reason: 'the seat itself survives');
    await bloc.close();
  });
}

class _NoopSyncDao implements SyncDao {
  @override
  Stream<void> watchLocalChanges() => const Stream<void>.empty();

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName} not needed');
}
