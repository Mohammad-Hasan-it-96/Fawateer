import '../../../core/network/sync_api_client.dart';
import '../domain/entities/sync_change.dart';
import '../domain/sync_transport.dart';

/// [SyncTransport] over the real `/api/v1/sync/*` endpoints.
///
/// Thin on purpose: everything that decides *what* to send lives in
/// `SyncEngine`, and everything about HTTP lives in [SyncApiClient]. This is
/// only the shape of the two payloads, which is exactly the part the backend
/// contract pins.
///
/// **Push and pull are one path, split by verb: `POST` and `GET /sync/changes`.**
/// The 2026-07-27 design named them `/sync/push` and `/sync/pull`, and the
/// client was built against that; what shipped is `/changes`, confirmed against
/// their routes on 2026-08-11 and again by probing production. Both design
/// names 404 — which is a *route* error carrying no typed code, so it fell to
/// `SyncError.server` and the shop was told "something went wrong, try again"
/// forever. Nothing distinguished it from a real outage, and no test could see
/// it: every sync test drives an in-memory relay that never has a URL at all.
const _kChangesEndpoint = 'sync/changes';
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
      _kChangesEndpoint,
      {'changes': changes.map((c) => c.toJson()).toList()},
      token: await _token(),
      // Generous relative to a normal request: a full batch is up to 200 rows
      // of payload on a shop's mobile connection.
      timeout: const Duration(seconds: 30),
    );

    // Per-row results. The server answers with three buckets because partial
    // success is normal; a client that only checked the HTTP status would
    // advance its watermark over rows the server refused.
    //
    // Read out of `data` first, then the top level. This platform wraps every
    // successful response as `{data: …, meta: …}` — verified on `/sync/changes`
    // and `/sync/devices` — but the push buckets were never pinned in writing,
    // so the flat shape stays as a fallback. Guessing wrong here is silent:
    // empty buckets read as "the server accepted nothing", which stalls the
    // watermark forever and re-sends the same rows every pass.
    final data = json['data'];
    final body = data is Map<String, dynamic> ? data : json;
    return PushResult(
      accepted: _uuids(body['accepted']),
      rejected: _uuids(body['rejected']),
      conflicts: _uuids(body['conflicts']),
    );
  }

  @override
  Future<PullPage> pull({required int since, int limit = 200}) async {
    final json = await _client.getJson(
      '$_kChangesEndpoint?since=$since&limit=$limit',
      token: await _token(),
      timeout: const Duration(seconds: 30),
    );

    // **The page is `data`, and the cursor lives in `meta`.**
    // `{"data":[…rows…],"meta":{"next_cursor":N,"has_more":false}}`, read off
    // production 2026-08-16. The design document's flat `{changes, next_cursor,
    // has_more}` is kept only as a fallback.
    //
    // This one is worse than a wrong URL, because it *succeeds*: reading
    // `json['changes']` on the real envelope finds nothing, so every pull
    // returns an empty page and the device reports "up to date" while the other
    // phone's sales sit unread on the server. A wrong URL at least errors.
    final meta = json['meta'];
    final metaMap = meta is Map ? meta : const {};
    final raw = json['data'] is List ? json['data'] : json['changes'];
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

    final next = metaMap['next_cursor'] ?? json['next_cursor'];
    final more = metaMap['has_more'] ?? json['has_more'];
    return PullPage(
      changes: changes,
      // Falls back to `since`, never to 0: a missing cursor must leave the
      // device where it was, not send it back to replay the shop's history.
      nextCursor: next is int ? next : int.tryParse('$next') ?? since,
      hasMore: more == true,
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
