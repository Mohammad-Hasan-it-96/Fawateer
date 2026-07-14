import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../domain/entities/backup_info.dart';
import '../domain/entities/backup_manifest.dart';

/// Thrown when an authenticated Drive client can't be obtained (user not signed
/// in, or consent for the scope was not granted).
class NotSignedInException implements Exception {}

/// Google Drive storage target for backups, using the `drive.file` scope only
/// (the app sees only the files it created — a non-sensitive scope, so no Google
/// verification and no Play Console). Backups live in a visible "Fawateer
/// Backups" folder in the user's own Drive.
class GoogleDriveBackupTarget {
  final GoogleSignIn _signIn = GoogleSignIn(
    scopes: const [drive.DriveApi.driveFileScope],
  );

  static const _folderName = 'Fawateer Backups';
  static const _folderMime = 'application/vnd.google-apps.folder';
  static const _backupMime = 'application/x-sqlite3';

  // ── Account ────────────────────────────────────────────────────────────
  Future<bool> isSignedIn() => _signIn.isSignedIn();

  Future<String?> signIn() async {
    final account = await _signIn.signIn(); // null if the user cancels
    return account?.email;
  }

  Future<String?> currentAccountEmail() async {
    final existing = _signIn.currentUser;
    if (existing != null) return existing.email;
    final silent = await _signIn.signInSilently();
    return silent?.email;
  }

  Future<void> signOut() => _signIn.signOut();

  // ── Drive plumbing ───────────────────────────────────────────────────────
  Future<drive.DriveApi> _api() async {
    // Ensure we have a session (silent first; the interactive sign-in happens
    // via [signIn] from the UI).
    _signIn.currentUser ?? await _signIn.signInSilently();
    final client = await _signIn.authenticatedClient();
    if (client == null) throw NotSignedInException();
    return drive.DriveApi(client);
  }

  /// Find the "Fawateer Backups" folder, creating it if missing.
  Future<String> _folderId(drive.DriveApi api) async {
    const q =
        "mimeType='$_folderMime' and name='$_folderName' and trashed=false";
    final found = await api.files.list(q: q, $fields: 'files(id)', spaces: 'drive');
    if ((found.files ?? []).isNotEmpty) return found.files!.first.id!;

    final folder = drive.File()
      ..name = _folderName
      ..mimeType = _folderMime;
    final created = await api.files.create(folder, $fields: 'id');
    return created.id!;
  }

  // ── Operations ───────────────────────────────────────────────────────────
  Future<void> upload(File file, BackupManifest manifest) async {
    final api = await _api();
    final folderId = await _folderId(api);
    final length = await file.length();

    final meta = drive.File()
      ..name = 'fawateer-${manifest.createdAt.toIso8601String()}.sqlite'
      ..mimeType = _backupMime
      ..parents = [folderId]
      ..appProperties = manifest.toDriveProperties();

    final media = drive.Media(file.openRead(), length, contentType: _backupMime);
    await api.files.create(meta, uploadMedia: media);
  }

  Future<List<BackupInfo>> list(String currentDeviceId) async {
    final api = await _api();
    final folderId = await _folderId(api);
    final q =
        "'$folderId' in parents and trashed=false and appProperties has { key='app' and value='${BackupManifest.appTag}' }";
    final res = await api.files.list(
      q: q,
      spaces: 'drive',
      orderBy: 'createdTime desc',
      $fields: 'files(id,name,size,createdTime,appProperties)',
    );

    return (res.files ?? []).map((f) {
      final props = (f.appProperties ?? {}).cast<String, String>();
      final m = BackupManifest.fromDriveProperties(props);
      return BackupInfo(
        id: f.id!,
        name: f.name ?? '',
        createdAt: (f.createdTime?.toLocal()) ?? m.createdAt,
        sizeBytes: int.tryParse(f.size ?? '') ?? 0,
        schemaVersion: m.schemaVersion,
        sha256: m.sha256,
        deviceId: m.deviceId,
        summary: m.summary,
        fromThisDevice: m.deviceId.isNotEmpty && m.deviceId == currentDeviceId,
      );
    }).toList();
  }

  /// Download the file bytes for [fileId] into [dest].
  Future<File> download(String fileId, File dest) async {
    final api = await _api();
    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final sink = dest.openWrite();
    await media.stream.pipe(sink);
    await sink.close();
    return dest;
  }
}
