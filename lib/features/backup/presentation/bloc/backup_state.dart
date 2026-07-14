part of 'backup_bloc.dart';

enum BackupBusy { idle, signingIn, backingUp, restoring, exporting }

/// One-shot success signals, consumed by a BlocListener on the page.
enum BackupSuccess { backedUp, restored, exported }

class BackupState extends Equatable {
  final bool signedIn;
  final String? email;
  final DateTime? lastBackupAt;
  final List<BackupInfo> backups;
  final bool loadingList;
  final BackupBusy busy;

  /// Transient, cleared after the page reacts (see [copyWith] `clearMessage`).
  final Failure? error;
  final BackupSuccess? success;

  /// The snapshot produced by an export, to hand to the share sheet.
  final File? exportedFile;

  const BackupState({
    this.signedIn = false,
    this.email,
    this.lastBackupAt,
    this.backups = const [],
    this.loadingList = false,
    this.busy = BackupBusy.idle,
    this.error,
    this.success,
    this.exportedFile,
  });

  bool get isBusy => busy != BackupBusy.idle;

  BackupState copyWith({
    bool? signedIn,
    String? email,
    bool clearEmail = false,
    DateTime? lastBackupAt,
    List<BackupInfo>? backups,
    bool? loadingList,
    BackupBusy? busy,
    Failure? error,
    BackupSuccess? success,
    File? exportedFile,
    bool clearMessage = false,
  }) {
    return BackupState(
      signedIn: signedIn ?? this.signedIn,
      email: clearEmail ? null : (email ?? this.email),
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      backups: backups ?? this.backups,
      loadingList: loadingList ?? this.loadingList,
      busy: busy ?? this.busy,
      // error/success/exportedFile are transient: a normal copyWith clears them
      // unless explicitly set, so they fire once. `clearMessage` is available
      // for callers that want to be explicit.
      error: clearMessage ? null : error,
      success: clearMessage ? null : success,
      exportedFile: clearMessage ? null : exportedFile,
    );
  }

  @override
  List<Object?> get props => [
        signedIn,
        email,
        lastBackupAt,
        backups,
        loadingList,
        busy,
        error,
        success,
        exportedFile,
      ];
}
