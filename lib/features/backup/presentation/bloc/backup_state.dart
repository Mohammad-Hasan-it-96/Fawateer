part of 'backup_bloc.dart';

enum BackupBusy { idle, signingIn, backingUp, restoring, exporting }

/// One-shot success signals, consumed by a BlocListener on the page.
enum BackupSuccess { backedUp, restored, exported }

class BackupState extends Equatable {
  final bool signedIn;
  final String? email;

  /// Masked account the server has on record (e.g. `y••••n@gmail.com`), shown
  /// only while signed out — it tells a reinstalled user which account holds
  /// their backups. Never a usable address.
  final String? accountHint;
  final DateTime? lastBackupAt;

  /// Whether the daily automatic backup is on (see [AutoBackupService]).
  final bool autoEnabled;

  /// False on a linked (non-owner) phone: it may restore, never back up.
  /// Defaults to true so a single-phone shop — and the first frame, before the
  /// role has been read — is never wrongly told it cannot back up.
  final bool canBackUp;

  /// True when this phone shares its shop with others — the restore dialog
  /// then has to say that they must be linked again. See
  /// [AutoBackupService.isLinkedToOtherPhones].
  final bool isLinked;
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
    this.accountHint,
    this.lastBackupAt,
    this.autoEnabled = true,
    this.canBackUp = true,
    this.isLinked = false,
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
    String? accountHint,
    bool clearEmail = false,
    DateTime? lastBackupAt,
    bool? autoEnabled,
    bool? canBackUp,
    bool? isLinked,
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
      accountHint: accountHint ?? this.accountHint,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      autoEnabled: autoEnabled ?? this.autoEnabled,
      canBackUp: canBackUp ?? this.canBackUp,
      isLinked: isLinked ?? this.isLinked,
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
        accountHint,
        lastBackupAt,
        canBackUp,
        isLinked,
        autoEnabled,
        backups,
        loadingList,
        busy,
        error,
        success,
        exportedFile,
      ];
}
