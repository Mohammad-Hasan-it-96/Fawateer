import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../domain/entities/subscription_plan.dart';

/// Thin wrapper over [ApiClient] for the license endpoints. Returns decoded
/// maps (repository maps them to entities); throws [ApiException] on transport
/// errors so the repository can distinguish offline from server rejection.
class LicenseRemoteDataSource {
  final ApiClient _client;
  const LicenseRemoteDataSource(this._client);

  /// `POST check_device` — status poll. Returns the decoded body, or `null`
  /// when the server rejects the device (non-2xx / bad body) which we treat as
  /// "not verified". A genuine offline error ([ApiException.isOffline]) is
  /// rethrown so the caller can fall back to cache within grace.
  Future<Map<String, dynamic>?> checkDevice(String deviceId) async {
    try {
      return await _client.postJson('check_device', {
        'device_id': deviceId,
        'app_name': ApiConfig.appName,
      });
    } on ApiException catch (e) {
      if (e.isOffline) rethrow;
      return null; // server said no / unparseable → unverified
    }
  }

  /// `POST create_device` — register the device / (re-)request activation.
  /// When [fcmToken] is provided it's attached so the server can push the
  /// live-unlock notification the moment an operator activates the device.
  Future<Map<String, dynamic>> createDevice({
    required String deviceId,
    required String name,
    required String phone,
    String? fcmToken,
  }) {
    return _client.postJson('create_device', {
      'app_name': ApiConfig.appName,
      'device_id': deviceId,
      'full_name': name,
      'phone': phone,
      if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
    });
  }

  /// `POST update_my_data` — refresh just the FCM token for an already-known
  /// device (used on token rotation, when name/phone aren't needed).
  Future<void> updateFcmToken({
    required String deviceId,
    required String fcmToken,
  }) async {
    await _client.postJson('update_my_data', {
      'app_name': ApiConfig.appName,
      'device_id': deviceId,
      'fcm_token': fcmToken,
    });
  }

  /// `POST update_my_data` — update the agent's name/phone for an already-known
  /// device (edited from Settings). Throws [ApiException] on transport errors so
  /// the caller can report whether the server was synced.
  Future<void> updateAgentData({
    required String deviceId,
    required String name,
    required String phone,
  }) async {
    await _client.postJson('update_my_data', {
      'app_name': ApiConfig.appName,
      'device_id': deviceId,
      'full_name': name,
      'phone': phone,
    });
  }

  /// `POST update_my_data` — record which Google account holds this device's
  /// Drive backups, so support can see it and a reinstalled app can be reminded
  /// which account to sign into. Sent alone (the endpoint takes every field as
  /// optional); throws [ApiException] on transport errors.
  Future<void> updateGoogleAccount({
    required String deviceId,
    required String googleAccount,
  }) async {
    await _client.postJson('update_my_data', {
      'app_name': ApiConfig.appName,
      'device_id': deviceId,
      'google_account': googleAccount,
    });
  }

  /// `POST create_device` with a pending plan request (operator-driven flow).
  Future<Map<String, dynamic>> requestPlan({
    required String deviceId,
    required String name,
    required String phone,
    required String requestedPlan,
    required String contactMethod,
  }) {
    return _client.postJson('create_device', {
      'app_name': ApiConfig.appName,
      'device_id': deviceId,
      'full_name': name,
      'phone': phone,
      'requested_plan': requestedPlan,
      'contact_method': contactMethod,
      'status': 'pending',
    });
  }

  /// `GET getPlans` — the plan catalog. Returns `[]` if the payload is empty.
  Future<List<SubscriptionPlan>> getPlans() async {
    final body = await _client.getJson('getPlans');
    final currency = body['currency'];
    final code = (currency is Map ? currency['code'] : '')?.toString() ?? '';
    final symbol = (currency is Map ? currency['symbol'] : '')?.toString() ?? '';
    final raw = body['plans'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => SubscriptionPlan.fromJson(
              m.cast<String, dynamic>(),
              currencyCode: code,
              currencySymbol: symbol,
            ))
        .where((p) => p.enabled)
        .toList();
  }
}
