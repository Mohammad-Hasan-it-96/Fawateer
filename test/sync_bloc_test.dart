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
