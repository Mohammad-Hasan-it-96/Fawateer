// Restore is the highest-blast-radius path in the app: it closes the live DB
// connection and swaps the file underneath it. That creates two *different*
// kinds of failure, and conflating them is what these tests guard against.
//
// Fail **before** the close (bad download, checksum mismatch, schema too new)
// and the app is untouched and perfectly healthy — a snackbar is the right
// response. Fail **after** it and the app can no longer reach SQLite at all;
// every subsequent query throws. Both used to surface as the same generic
// error, so the second case showed a dismissable "something went wrong" and
// then let the shopkeeper carry on into a POS where nothing worked — looking,
// from behind the counter, exactly like the restore had eaten their data.
import 'package:billing_app/core/error/failure.dart';
import 'package:billing_app/features/backup/data/auto_backup_service.dart';
import 'package:billing_app/features/backup/data/backup_engine.dart';
import 'package:billing_app/features/backup/domain/entities/backup_info.dart';
import 'package:billing_app/features/backup/domain/repositories/backup_repository.dart';
import 'package:billing_app/features/backup/presentation/bloc/backup_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _FakeBackupRepository implements BackupRepository {
  final Failure? restoreFailure;
  _FakeBackupRepository({this.restoreFailure});

  @override
  Future<Either<Failure, Unit>> restore(BackupInfo info) async =>
      restoreFailure == null ? const Right(unit) : Left(restoreFailure!);

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

class _FakeAutoBackupService implements AutoBackupService {
  @override
  Future<bool> isEnabled() async => false;

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

BackupInfo _info() => BackupInfo(
      id: 'file-1',
      name: 'fawateer-1.sqlite',
      createdAt: DateTime(2026, 7, 26),
      sizeBytes: 1024,
      schemaVersion: 14,
      sha256: 'abc',
      deviceId: 'dev',
      summary: 'inv:1 cust:1 prod:1',
      fromThisDevice: true,
    );

/// Drive a restore that fails with [failure] and return the settled state.
Future<BackupState> _restoreWith(Failure failure) async {
  final bloc = BackupBloc(
    repository: _FakeBackupRepository(restoreFailure: failure),
    autoBackup: _FakeAutoBackupService(),
  );
  // Skip the transient `restoring` emission; assert on where it lands.
  final settled = bloc.stream.firstWhere((s) => s.busy == BackupBusy.idle);
  bloc.add(BackupRestoreRequested(_info()));
  final state = await settled;
  await bloc.close();
  return state;
}

void main() {
  group('RestoreRestartRequiredException', () {
    test('preserves the underlying cause instead of replacing it', () {
      final cause = StateError('disk full');
      final ex = RestoreRestartRequiredException(cause);

      expect(ex.cause, same(cause),
          reason: 'the real reason must survive for the debug log');
      expect(ex.toString(), contains('disk full'));
    });
  });

  group('BackupBloc restore failure', () {
    test('a failure past the point of no return is RestoreIncompleteFailure',
        () async {
      final state =
          await _restoreWith(const RestoreIncompleteFailure('disk full'));

      // The page keys the unmissable restart prompt off this exact type. If
      // someone "simplifies" the mapping back to a CacheFailure, the prompt
      // silently stops appearing and the zombie-app bug returns.
      expect(state.error, isA<RestoreIncompleteFailure>());
      expect(state.success, isNull,
          reason: 'a failed restore is not a success, however it is displayed');
    });

    test('an ordinary pre-close failure stays an ordinary failure', () async {
      final state =
          await _restoreWith(const IncompatibleFailure('checksum_mismatch'));

      // Guards the other direction: nothing is wrong with the app here, so it
      // must NOT nag the user to close it.
      expect(state.error, isA<IncompatibleFailure>());
      expect(state.error, isNot(isA<RestoreIncompleteFailure>()));
    });
  });
}
