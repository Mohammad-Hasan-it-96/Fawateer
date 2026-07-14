import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/backup_info.dart';
import '../../domain/repositories/backup_repository.dart';

part 'backup_event.dart';
part 'backup_state.dart';

class BackupBloc extends Bloc<BackupEvent, BackupState> {
  final BackupRepository _repo;

  BackupBloc({required BackupRepository repository})
      : _repo = repository,
        super(const BackupState()) {
    on<BackupStatusRequested>(_onStatus);
    on<BackupSignInRequested>(_onSignIn);
    on<BackupSignOutRequested>(_onSignOut);
    on<BackupNowRequested>(_onBackupNow);
    on<BackupListRequested>(_onList);
    on<BackupRestoreRequested>(_onRestore);
    on<BackupExportRequested>(_onExport);
  }

  Future<void> _onStatus(
      BackupStatusRequested e, Emitter<BackupState> emit) async {
    final signedIn = await _repo.isSignedIn();
    final email = signedIn ? await _repo.currentAccountEmail() : null;
    final last = await _repo.lastBackupAt();
    emit(state.copyWith(
      signedIn: signedIn,
      email: email,
      lastBackupAt: last,
      clearEmail: !signedIn,
    ));
    if (signedIn) add(const BackupListRequested());
  }

  Future<void> _onSignIn(
      BackupSignInRequested e, Emitter<BackupState> emit) async {
    emit(state.copyWith(busy: BackupBusy.signingIn, clearMessage: true));
    final res = await _repo.signIn();
    res.match(
      (f) => emit(state.copyWith(busy: BackupBusy.idle, error: f)),
      (email) {
        emit(state.copyWith(
            busy: BackupBusy.idle, signedIn: true, email: email));
        add(const BackupListRequested());
      },
    );
  }

  Future<void> _onSignOut(
      BackupSignOutRequested e, Emitter<BackupState> emit) async {
    await _repo.signOut();
    emit(state.copyWith(
      signedIn: false,
      clearEmail: true,
      backups: const [],
    ));
  }

  Future<void> _onBackupNow(
      BackupNowRequested e, Emitter<BackupState> emit) async {
    emit(state.copyWith(busy: BackupBusy.backingUp, clearMessage: true));
    final res = await _repo.backupNow();
    await res.match(
      (f) async => emit(state.copyWith(busy: BackupBusy.idle, error: f)),
      (info) async {
        emit(state.copyWith(
          busy: BackupBusy.idle,
          success: BackupSuccess.backedUp,
          lastBackupAt: info.createdAt,
        ));
        add(const BackupListRequested());
      },
    );
  }

  Future<void> _onList(
      BackupListRequested e, Emitter<BackupState> emit) async {
    emit(state.copyWith(loadingList: true));
    final res = await _repo.listBackups();
    res.match(
      (f) => emit(state.copyWith(loadingList: false, error: f)),
      (list) => emit(state.copyWith(loadingList: false, backups: list)),
    );
  }

  Future<void> _onRestore(
      BackupRestoreRequested e, Emitter<BackupState> emit) async {
    emit(state.copyWith(busy: BackupBusy.restoring, clearMessage: true));
    final res = await _repo.restore(e.info);
    res.match(
      (f) => emit(state.copyWith(busy: BackupBusy.idle, error: f)),
      // On success the DB connection is closed and the app must restart; the
      // page listens for this and prompts the user to reopen the app.
      (_) => emit(state.copyWith(
          busy: BackupBusy.idle, success: BackupSuccess.restored)),
    );
  }

  Future<void> _onExport(
      BackupExportRequested e, Emitter<BackupState> emit) async {
    emit(state.copyWith(busy: BackupBusy.exporting, clearMessage: true));
    final res = await _repo.exportLocalSnapshot();
    res.match(
      (f) => emit(state.copyWith(busy: BackupBusy.idle, error: f)),
      (file) => emit(state.copyWith(
          busy: BackupBusy.idle,
          success: BackupSuccess.exported,
          exportedFile: file)),
    );
  }
}
