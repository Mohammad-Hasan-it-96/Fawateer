import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/backup_info.dart';

/// Orchestrates snapshot creation + a pluggable storage target (currently
/// Google Drive). Follows the app's functional-error convention: every fallible
/// call returns `Either<Failure, T>`; the page maps the failure *type* to a
/// localized message.
///
/// Failure mapping used here:
/// - [NetworkFailure]     → offline / timed out reaching Drive.
/// - [ServerFailure]      → Drive reached but returned an error.
/// - [PermissionFailure]  → sign-in cancelled / not signed in.
/// - [IncompatibleFailure]→ backup is newer than this app (update required) or
///                          its checksum failed (corrupt/tampered).
/// - [CacheFailure]       → unexpected local/DB error.
abstract class BackupRepository {
  // ── Account ────────────────────────────────────────────────────────────
  Future<bool> isSignedIn();

  /// Interactive sign-in; returns the chosen account's email on success.
  Future<Either<Failure, String>> signIn();

  Future<void> signOut();

  /// The signed-in email (silent), or null if not signed in.
  Future<String?> currentAccountEmail();

  // ── Backup ─────────────────────────────────────────────────────────────
  /// Snapshot the DB and upload it. Records last-backup time locally.
  Future<Either<Failure, BackupInfo>> backupNow();

  Future<Either<Failure, List<BackupInfo>>> listBackups();

  /// Download + validate [info], then swap it in as the live DB. On success the
  /// caller MUST restart the app (the live connection has been closed).
  Future<Either<Failure, Unit>> restore(BackupInfo info);

  /// Build a local snapshot file (for the "export & share" fallback). Caller
  /// shares it and is responsible for nothing else; the temp file is short-lived.
  Future<Either<Failure, File>> exportLocalSnapshot();

  /// When the last successful cloud backup happened, or null if never.
  Future<DateTime?> lastBackupAt();

  /// A **masked** hint at the Google account the server has on record for this
  /// device (e.g. `y••••n@gmail.com`), or null if none is known.
  ///
  /// Its whole purpose is the reinstall case: local storage is empty, but the
  /// device id survives, so the server can still tell the user which account
  /// their backups are under. Never a usable address — see
  /// [LicenseRepository.cachedGoogleAccountHint].
  Future<String?> accountHint();
}
