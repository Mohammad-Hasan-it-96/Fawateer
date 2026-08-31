import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/database/sync_tables.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/sync_api_client.dart';
import '../../backup/data/backup_engine.dart';
import '../domain/entities/bootstrap_handoff.dart';
import '../domain/entities/join_invite.dart';
import '../domain/entities/join_token.dart';
import '../domain/entities/sync_session.dart';
import '../domain/repositories/sync_enrollment_repository.dart';
import '../domain/sync_error.dart';
import 'snapshot_seeder.dart';
import 'sync_credential_store.dart';
import 'sync_engine.dart';
import 'sync_state_store.dart';

/// What a completed bootstrap left behind.
enum BootstrapResult {
  /// There was no snapshot — only a starting cursor was adopted. The device
  /// carries on running normally.
  cursorOnly,

  /// The database was replaced. **The app must be restarted**; SQLite is closed
  /// and every query from here on throws.
  restartRequired,
}

/// Progress through the owner's multi-step invite preparation, so a screen can
/// say what is happening instead of spinning silently through a sync, a vacuum
/// and a multi-megabyte upload.
enum BootstrapStep { syncing, snapshotting, uploading }

/// Seeds a joining device with the shop it is joining (Plan 002, bootstrap;
/// ADR 0011 Decision 13).
///
/// **Why a snapshot at all, when there is a replication log?** Because rows
/// stamped `updated_at = ''` — everything that predates sync, which for an
/// existing shop is everything — are deliberately never pushed. Sending a year
/// of trading history row by row would be an enormous, pointless upload. So the
/// log carries what changed *since* sync began, and the snapshot carries the
/// shop. Without this a second phone joins and finds an empty shop, while the
/// first phone looks perfectly healthy — which reads to the shopkeeper as the
/// new phone being broken.
///
/// The ordering here is the part that took three rounds with the backend to get
/// right; see `docs/backend-replies/2026-07-29-fawateer-response.txt` §1.
class BootstrapService {
  final SyncEnrollmentRepository _enrollment;
  final SyncEngine _engine;
  final SyncStateStore _state;
  final BackupEngine _backup;
  final SnapshotSeeder _seeder;
  final SyncApiClient _api;
  final SyncCredentialStore _credentials;

  /// Where the snapshot goes when the mint response carries no `upload_url`:
  /// the token's own bootstrap sub-resource, `POST /sync/join-tokens/{t}/bootstrap`.
  ///
  /// Confirmed against their routes on 2026-08-11 and verified on production.
  /// The earlier guess (`sync/enroll/seed`, invented because the 2026-07-28 §H
  /// reply named an "upload target" without pinning a path) does not exist and
  /// 404s — see the note on [SyncApiTransport] for why that was invisible.
  static String seedEndpoint(String joinToken) =>
      'sync/join-tokens/$joinToken/bootstrap';

  /// The multipart fields that ride with the snapshot.
  ///
  /// A named function rather than a map literal inline for the same reason
  /// [seedEndpoint] is one: the wire spelling of these keys is a contract with
  /// the server that no in-memory relay can check, so it needs somewhere a test
  /// can point at. `test/sync_endpoints_test.dart` pins it.
  ///
  /// **The hash field is `snapshot_sha256`, not `sha256`.** We sent `sha256`
  /// until 2026-08-16 and it was never noticed, because the route was answering
  /// 404 before it ever reached validation (evotech-core bound `{token}` on a
  /// record uuid the mint never returns — their bug, fixed in their PR #35).
  /// With the 404 gone the next thing our old call would have hit is a 422,
  /// "The snapshot sha256 field is required." Confirmed in their
  /// 2026-08-16 reply, answer 3.
  ///
  /// `join_token` is redundant — the path segment already carries it and the
  /// server explicitly ignores the body copy (same reply). It is kept because
  /// it costs nothing and an unvalidated extra field is dropped either way, and
  /// because it records that the token is the *binding*, not the credential:
  /// the Bearer on this request is the owner's own seat token. Conflating the
  /// two would let anyone who photographed the QR replace the snapshot the
  /// joining device is about to trust with its whole shop (2026-07-29 H1).
  static Map<String, String> seedFields({
    required String joinToken,
    required int cursor,
    required String sha256,
  }) =>
      {
        'join_token': joinToken,
        'cursor': cursor.toString(),
        'snapshot_sha256': sha256,
      };

  const BootstrapService({
    required SyncEnrollmentRepository enrollment,
    required SyncEngine engine,
    required SyncStateStore state,
    required BackupEngine backup,
    required SnapshotSeeder seeder,
    required SyncApiClient api,
    required SyncCredentialStore credentials,
  })  : _enrollment = enrollment,
        _engine = engine,
        _state = state,
        _backup = backup,
        _seeder = seeder,
        _api = api,
        _credentials = credentials;

  /// Owner side: get this shop into a state another phone can be seeded from,
  /// then mint the invitation that points at it.
  ///
  /// The order is load-bearing at every step:
  ///
  /// 1. **Sync fully — push *and* pull.** Pushing alone was the version the
  ///    backend and we both signed off on, and it loses data: a second device's
  ///    change that this owner has not pulled is in neither the owner's database
  ///    (so not in the snapshot) nor below the reported cursor (so never pulled
  ///    by the joiner). It needs only two existing devices to happen, and it
  ///    fails silently.
  /// 2. **Mint after syncing, not before.** The token is single-use and expires
  ///    in minutes; burning one on a pass that turns out to be offline means the
  ///    owner shows the other phone a code that is already dead.
  /// 3. **Read our own cursor, and read it *before* the vacuum.** Ours, because
  ///    it means precisely "everything at or below this is applied to my
  ///    database" — the server cannot answer that, which was the original error.
  ///    Before, because a pull landing while the vacuum runs would put a
  ///    later-read cursor above content the snapshot does not contain. Reading
  ///    early errs in the harmless direction: the snapshot may hold slightly
  ///    more than the cursor covers, and the joiner re-pulls a few rows it
  ///    already has, which the merge absorbs.
  /// 4. **Upload before showing the code**, because the hash the joiner will
  ///    check does not exist until the snapshot does (2026-07-29 H2).
  Future<Either<Failure, JoinInvite>> prepareInvite({
    void Function(BootstrapStep)? onStep,
  }) async {
    final session = await _credentials.load();
    if (session == null) {
      return const Left(
          SyncFailure(SyncError.subscriptionRequired, 'not enrolled'));
    }

    onStep?.call(BootstrapStep.syncing);
    final pass = await _engine.sync();
    if (pass.error != null) {
      // Refused rather than seeded from a database we know is behind. A snapshot
      // taken now would be missing whatever the failed pass could not move, and
      // nothing downstream would ever notice.
      // The pass's own detail, not a fixed label. 'pre-seed sync failed' is
      // true and says nothing — and this is the one screen where the raw server
      // message is reachable (long-press the status row), so replacing it with
      // our own words is throwing away the only diagnosis a shop can send us.
      return Left(SyncFailure(
          pass.error!, pass.errorDetail ?? 'pre-seed sync failed'));
    }

    final minted = await _enrollment.mintJoinToken();
    return await minted.match(
      (failure) async => Left<Failure, JoinInvite>(failure),
      (token) => _seed(session, token, onStep),
    );
  }

  Future<Either<Failure, JoinInvite>> _seed(
    SyncSession session,
    JoinToken token,
    void Function(BootstrapStep)? onStep,
  ) async {
    File? snapshot;
    try {
      final cursor = await _state.pullCursor();

      onStep?.call(BootstrapStep.snapshotting);
      final (file, manifest) = await _backup.createSnapshot();
      snapshot = file;

      onStep?.call(BootstrapStep.uploading);
      await _api.postFile(
        token.uploadUrl ?? seedEndpoint(token.token),
        file,
        fields: seedFields(
          joinToken: token.token,
          cursor: cursor,
          sha256: manifest.sha256,
        ),
        token: session.syncToken,
      );

      return Right(JoinInvite(token: token, snapshotSha256: manifest.sha256));
    } catch (e) {
      return Left(_map(e));
    } finally {
      await _discard(snapshot);
    }
  }

  /// Joining side: apply the seed the owner left for us.
  ///
  /// [expectedSha256] is the hash carried in the scanned invitation. It is
  /// preferred over the one the server declares in [handoff], because a server
  /// vouching for its own delivery certifies transit and nothing more. A typed
  /// code has no hash, and falls back to the server's — a narrower guarantee,
  /// spelled out on [JoinInvite].
  ///
  /// Returns [BootstrapResult.restartRequired] on success: the live database has
  /// been replaced and the connection is closed.
  Future<Either<Failure, BootstrapResult>> adopt(
    BootstrapHandoff handoff, {
    String? expectedSha256,
  }) async {
    if (!handoff.hasSnapshot) {
      // A shop's first device: it is establishing the business, not joining one,
      // so there is nothing to restore and nothing to restart for.
      await _engine.adoptBootstrap(handoff.cursor);
      return const Right(BootstrapResult.cursorOnly);
    }

    File? file;
    try {
      final bytes = await _api.downloadBytes(handoff.snapshotUrl!);

      // Integrity first, before anything touches the disk — a restore that has
      // begun cannot be un-begun, and this is the last point at which failing is
      // free.
      final expected = (expectedSha256?.isNotEmpty ?? false)
          ? expectedSha256!
          : (handoff.snapshotSha256 ?? '');
      // No hash at all is a refusal, not a free pass. This is the shop's entire
      // database arriving through a third party; restoring it unverified would
      // trade the one guarantee the design has for the convenience of not
      // failing. It is also not a "skip" — skipping leaves the phone in an
      // empty shop with nothing to report.
      if (expected.isEmpty || sha256.convert(bytes).toString() != expected) {
        return const Left(IncompatibleFailure('checksum_mismatch'));
      }

      final dir = await getTemporaryDirectory();
      file = File('${dir.path}${Platform.pathSeparator}sync-seed.sqlite');
      if (await file.exists()) await file.delete();
      await file.writeAsBytes(bytes, flush: true);

      // Downgrade guard, same rule as a Drive restore: Drift migrations are
      // forward-only, so a snapshot from a newer build corrupts silently in an
      // older one. Read from SQLite's own `user_version` because, unlike a Drive
      // backup, this file arrives with no manifest beside it.
      final version = await _seeder.schemaVersionOf(file.path);
      if (version > _backup.schemaVersion) {
        return const Left(IncompatibleFailure('schema_too_new'));
      }

      // Write our starting position *into* the incoming file — after the swap
      // there is no open database left to write it to. See [SnapshotSeeder].
      await _seeder.seed(
        file.path,
        cursor: handoff.cursor,
        watermark: await _seeder.highestHlcIn(
            file.path, kSyncTables.map((t) => t.table).toList()),
      );

      await _backup.restoreSnapshot(file);
      return const Right(BootstrapResult.restartRequired);
    } catch (e) {
      return Left(_map(e));
    } finally {
      await _discard(file);
    }
  }

  /// The snapshot is the shop's entire unencrypted books sitting in a temp
  /// directory, so it is deleted whichever way the operation went.
  Future<void> _discard(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {/* temp file; a leftover must not fail the operation */}
  }

  Failure _map(Object e) {
    // Checked first: this one describes the state the *app* was left in, not the
    // kind of I/O that failed, and the generic arms below would swallow it.
    if (e is RestoreRestartRequiredException) {
      return RestoreIncompleteFailure(e.cause.toString());
    }
    if (e is SyncApiException) {
      if (e.isOffline) return NetworkFailure(e.message);
      return SyncFailure(SyncError.fromCode(e.code), e.message);
    }
    return CacheFailure(e.toString());
  }
}
