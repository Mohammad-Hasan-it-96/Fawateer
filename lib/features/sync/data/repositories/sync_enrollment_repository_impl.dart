import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/sync_api_client.dart';
import '../../../licensing/data/services/device_identity_service.dart';
import '../../domain/entities/bootstrap_handoff.dart';
import '../../domain/entities/enrollment_outcome.dart';
import '../../domain/entities/join_token.dart';
import '../../domain/entities/sync_device_registry.dart';
import '../../domain/entities/sync_seat_role.dart';
import '../../domain/entities/sync_session.dart';
import '../../domain/repositories/sync_enrollment_repository.dart';
import '../../domain/sync_error.dart';
import '../sync_credential_store.dart';

/// [SyncEnrollmentRepository] over the sync API + local credential store.
///
/// Identity is the licensing device id (the same anchor the server keys on), so
/// enrollment reuses [DeviceIdentityService] rather than minting a second id.
/// Every `SyncApiException` is mapped to the app's `Failure` taxonomy: offline →
/// [NetworkFailure]; a typed server code → [SyncFailure]; anything else →
/// [ServerFailure]/[CacheFailure].
class SyncEnrollmentRepositoryImpl implements SyncEnrollmentRepository {
  final SyncApiClient _api;
  final SyncCredentialStore _store;
  final DeviceIdentityService _identity;

  const SyncEnrollmentRepositoryImpl(this._api, this._store, this._identity);

  @override
  Future<Either<Failure, EnrollmentOutcome>> establishAsOwner({String? pushToken}) {
    return _enroll('sync/business', (deviceId) => {
          'app_name': ApiConfig.appName,
          'device_id': deviceId,
          if (pushToken != null) 'push_token': pushToken,
        });
  }

  @override
  Future<Either<Failure, EnrollmentOutcome>> joinBusiness(
    String joinToken, {
    String? pushToken,
  }) {
    return _enroll('sync/enroll', (deviceId) => {
          'join_token': joinToken,
          'device_id': deviceId,
          if (pushToken != null) 'push_token': pushToken,
        });
  }

  Future<Either<Failure, EnrollmentOutcome>> _enroll(
    String endpoint,
    Map<String, dynamic> Function(String deviceId) body,
  ) async {
    try {
      final deviceId = await _identity.getDeviceId();
      final json = await _api.postJson(endpoint, body(deviceId));
      final outcome = _outcomeFromData(_data(json));
      await _store.save(outcome.session);
      return Right(outcome);
    } on SyncApiException catch (e) {
      if (e.isOffline) return Left(NetworkFailure(e.message));
      return Left(SyncFailure(SyncError.fromCode(e.code), e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, JoinToken>> mintJoinToken() async {
    return _guarded((session) async {
      final json = await _api
          .postJson('sync/enroll/token', const {}, token: session.syncToken);
      return JoinToken.fromJson(_data(json));
    });
  }

  @override
  Future<Either<Failure, SyncDeviceRegistry>> listDevices() async {
    return _guarded((session) async {
      final json = await _api.getJson('sync/devices', token: session.syncToken);
      return SyncDeviceRegistry.fromJson(
        _data(json),
        envelope: json,
        currentSeat: session.seatUuid,
      );
    });
  }

  @override
  Future<Either<Failure, Unit>> revokeDevice(String seatUuid) async {
    return _guarded((session) async {
      await _api.delete('sync/devices/$seatUuid', token: session.syncToken);
      return unit;
    });
  }

  /// Run an owner-authenticated call, mapping the failure taxonomy once.
  ///
  /// The local no-seat check is not redundant with the server's: without a seat
  /// there is no Bearer credential to send at all, and the call would come back
  /// as a bare 401 carrying no typed code — which the owner would see as a
  /// generic "something went wrong".
  Future<Either<Failure, T>> _guarded<T>(
      Future<T> Function(SyncSession session) body) async {
    try {
      final session = await _store.load();
      if (session == null) {
        return const Left(
            SyncFailure(SyncError.subscriptionRequired, 'not enrolled'));
      }
      return Right(await body(session));
    } on SyncApiException catch (e) {
      if (e.isOffline) return Left(NetworkFailure(e.message));
      return Left(SyncFailure(SyncError.fromCode(e.code), e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<SyncSession?> currentSession() => _store.load();

  @override
  Future<void> leave() => _store.clear();

  Map<String, dynamic> _data(Map<String, dynamic> json) {
    final data = json['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  EnrollmentOutcome _outcomeFromData(Map<String, dynamic> data) {
    final seat = data['seat'] is Map<String, dynamic>
        ? data['seat'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final bootstrap = data['bootstrap'] is Map<String, dynamic>
        ? data['bootstrap'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final allowance = data['device_allowance'];

    final session = SyncSession(
      syncToken: data['sync_token']?.toString() ?? '',
      businessUuid: data['business_uuid']?.toString() ?? '',
      seatUuid: seat['uuid']?.toString() ?? '',
      role: SyncSeatRole.fromName(seat['role']?.toString()),
      // Present on owner onboarding; a member join omits it (owner-only concern).
      deviceAllowance: allowance is int ? allowance : int.tryParse('$allowance') ?? 0,
    );

    return EnrollmentOutcome(
      session: session,
      bootstrap: BootstrapHandoff.fromJson(bootstrap),
    );
  }
}
