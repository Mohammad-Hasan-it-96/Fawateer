part of 'backup_bloc.dart';

sealed class BackupEvent extends Equatable {
  const BackupEvent();
  @override
  List<Object?> get props => [];
}

/// Load sign-in status + last-backup time (and the list if signed in).
class BackupStatusRequested extends BackupEvent {
  const BackupStatusRequested();
}

class BackupSignInRequested extends BackupEvent {
  const BackupSignInRequested();
}

class BackupSignOutRequested extends BackupEvent {
  const BackupSignOutRequested();
}

class BackupNowRequested extends BackupEvent {
  const BackupNowRequested();
}

class BackupListRequested extends BackupEvent {
  const BackupListRequested();
}

class BackupRestoreRequested extends BackupEvent {
  final BackupInfo info;
  const BackupRestoreRequested(this.info);
  @override
  List<Object?> get props => [info];
}

class BackupExportRequested extends BackupEvent {
  const BackupExportRequested();
}
