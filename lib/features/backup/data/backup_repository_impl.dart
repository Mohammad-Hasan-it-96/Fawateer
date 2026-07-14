import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/daos/settings_dao.dart';
import '../../../core/error/failure.dart';
import '../../licensing/data/services/device_identity_service.dart';
import '../domain/entities/backup_info.dart';
import '../domain/repositories/backup_repository.dart';
import 'backup_engine.dart';
import 'google_drive_backup_target.dart';

class BackupRepositoryImpl implements BackupRepository {
  final BackupEngine _engine;
  final GoogleDriveBackupTarget _drive;
  final SettingsDao _settings;
  final DeviceIdentityService _deviceIdentity;

  const BackupRepositoryImpl(
    this._engine,
    this._drive,
    this._settings,
    this._deviceIdentity,
  );

  static const _kLastBackupAt = 'backup_last_at';
  static const _kLastEmail = 'backup_account_email';

  // ── Account ────────────────────────────────────────────────────────────
  @override
  Future<bool> isSignedIn() => _drive.isSignedIn();

  @override
  Future<Either<Failure, String>> signIn() async {
    try {
      final email = await _drive.signIn();
      if (email == null) {
        return const Left(PermissionFailure('sign_in_cancelled'));
      }
      await _settings.setValue(_kLastEmail, email);
      return Right(email);
    } catch (e) {
      return Left(_map(e));
    }
  }

  @override
  Future<void> signOut() => _drive.signOut();

  @override
  Future<String?> currentAccountEmail() => _drive.currentAccountEmail();

  // ── Backup ─────────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, BackupInfo>> backupNow() async {
    File? snapshot;
    try {
      final (file, manifest) = await _engine.createSnapshot();
      snapshot = file;
      await _drive.upload(file, manifest);

      final now = DateTime.now();
      await _settings.setValue(_kLastBackupAt, now.toIso8601String());
      final email = await _drive.currentAccountEmail();
      if (email != null) await _settings.setValue(_kLastEmail, email);

      final deviceId = manifest.deviceId;
      return Right(BackupInfo(
        id: '',
        name: file.uri.pathSegments.last,
        createdAt: now,
        sizeBytes: await file.length(),
        schemaVersion: manifest.schemaVersion,
        sha256: manifest.sha256,
        deviceId: deviceId,
        summary: manifest.summary,
        fromThisDevice: true,
      ));
    } catch (e) {
      return Left(_map(e));
    } finally {
      if (snapshot != null && await snapshot.exists()) {
        try {
          await snapshot.delete();
        } catch (_) {/* temp file; ignore */}
      }
    }
  }

  @override
  Future<Either<Failure, List<BackupInfo>>> listBackups() async {
    try {
      final deviceId = await _deviceIdentity.getDeviceId();
      return Right(await _drive.list(deviceId));
    } catch (e) {
      return Left(_map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> restore(BackupInfo info) async {
    // Downgrade guard: never restore a backup made by a NEWER app build.
    if (info.schemaVersion > _engine.schemaVersion) {
      return const Left(IncompatibleFailure('schema_too_new'));
    }

    File? tmp;
    try {
      final dir = await getTemporaryDirectory();
      tmp = File(
          '${dir.path}${Platform.pathSeparator}restore-${info.id}.sqlite');
      if (await tmp.exists()) await tmp.delete();

      await _drive.download(info.id, tmp);

      // Integrity guard: verify checksum before touching the live DB.
      if (info.sha256.isNotEmpty) {
        final bytes = await tmp.readAsBytes();
        final digest = sha256.convert(bytes).toString();
        if (digest != info.sha256) {
          return const Left(IncompatibleFailure('checksum_mismatch'));
        }
      }

      await _engine.restoreSnapshot(tmp);
      return const Right(unit);
    } catch (e) {
      return Left(_map(e));
    } finally {
      if (tmp != null && await tmp.exists()) {
        try {
          await tmp.delete();
        } catch (_) {/* ignore */}
      }
    }
  }

  @override
  Future<Either<Failure, File>> exportLocalSnapshot() async {
    try {
      final (file, _) = await _engine.createSnapshot();
      return Right(file);
    } catch (e) {
      return Left(_map(e));
    }
  }

  @override
  Future<DateTime?> lastBackupAt() async {
    final raw = await _settings.getValue(_kLastBackupAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  // ── Error mapping ────────────────────────────────────────────────────────
  Failure _map(Object e) {
    if (e is NotSignedInException) {
      return const PermissionFailure('not_signed_in');
    }
    if (e is SocketException || e is TimeoutException) {
      return NetworkFailure(e.toString());
    }
    if (e is drive.DetailedApiRequestError) {
      return ServerFailure('drive ${e.status}: ${e.message}');
    }
    return CacheFailure(e.toString());
  }
}
