import '../../../core/network/sync_api_client.dart';
import '../domain/entities/sync_change.dart';
import '../domain/sync_transport.dart';

/// [SyncTransport] over the real `/api/v1/sync/*` endpoints.
///
/// Thin on purpose: everything that decides *what* to send lives in
/// `SyncEngine`, and everything about HTTP lives in [SyncApiClient]. This is
/// only the shape of the two payloads, which is exactly the part the backend
/// contract pins.
class SyncApiTransport implements SyncTransport {
  final SyncApiClient _client;

  /// Supplies the current Bearer credential. A getter rather than a stored
  /// string because the seat token is rotated (re-enrolling as owner mints a
  /// new one) and a captured copy would keep sending the dead one until the
  /// app restarted.
  final Future<String?> Function() _token;

  const SyncApiTransport(this._client, this._token);

  @override
  Future<PushResult> push(List<SyncChange> changes) async {
    if (changes.isEmpty) return const PushResult();
    final json = await _client.postJson(
      'sync/push',
      {'changes': changes.map((c) => c.toJson()).toList()},
      token: await _token(),
      // Generous relative to a normal request: a full batch is up to 200 rows
      // of payload on a shop's mobile connection.
      timeout: const Duration(seconds: 30),
    );

    // Per-row results. The server answers with three buckets because partial
    // success is normal; a client that only checked the HTTP status would
    // advance its watermark over rows the server refused.
    return PushResult(
      accepted: _uuids(json['accepted']),
      rejected: _uuids(json['rejected']),
      conflicts: _uuids(json['conflicts']),
    );
  }

  @override
  Future<PullPage> pull({required int since, int limit = 200}) async {
    final json = await _client.getJson(
      'sync/pull?since=$since&limit=$limit',
      token: await _token(),
      timeout: const Duration(seconds: 30),
    );

    final raw = json['changes'];
    final changes = <SyncChange>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final change = SyncChange.fromJson(Map<String, dynamic>.from(item));
        // A malformed row is skipped, not fatal. One bad row in a page of 200
        // must not wedge the device forever — and because the cursor still
        // advances, it will not be re-read on every tick either.
        if (change != null) changes.add(change);
      }
    }

    final next = json['next_cursor'];
    return PullPage(
      changes: changes,
      // Falls back to `since`, never to 0: a missing cursor must leave the
      // device where it was, not send it back to replay the shop's history.
      nextCursor: next is int ? next : int.tryParse('$next') ?? since,
      hasMore: json['has_more'] == true,
    );
  }

  /// The server may answer either a list of uuid strings or a list of objects
  /// (`{"row_uuid": …, "reason": …}` for the rejected bucket). Both are read the
  /// same way so a shape change on one bucket cannot silently produce an empty
  /// set — which would look like "the server accepted nothing".
  static Set<String> _uuids(dynamic value) {
    if (value is! List) return const {};
    final out = <String>{};
    for (final item in value) {
      if (item is Map) {
        final uuid = item['row_uuid']?.toString();
        if (uuid != null && uuid.isNotEmpty) out.add(uuid);
      } else if (item != null) {
        out.add(item.toString());
      }
    }
    return out;
  }
}
