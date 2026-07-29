import 'entities/sync_change.dart';

/// What the server gave back for one page of `GET /api/v1/sync/pull`.
class PullPage {
  final List<SyncChange> changes;

  /// Where to resume. **The highest seq the server EXAMINED, not the highest it
  /// returned** — pinned in the 2026-07-29 exchange. Those differ whenever the
  /// server filters rows out of a page (another device's changes the caller
  /// need not see), and advancing to the highest *returned* would re-read the
  /// filtered tail forever, or — worse, if the filter is on the far side of the
  /// limit — skip rows permanently.
  final int nextCursor;

  final bool hasMore;

  const PullPage({
    required this.changes,
    required this.nextCursor,
    required this.hasMore,
  });

  static const empty = PullPage(changes: [], nextCursor: 0, hasMore: false);
}

/// What the server did with a pushed batch.
///
/// **Partial success is normal** (ADR 0011): the server answers per row, so a
/// batch can be half accepted. The engine must therefore not advance its
/// watermark past a row the server did not take.
class PushResult {
  /// Row uuids the server accepted (or already had — a re-push no-ops by
  /// idempotency key and still counts as accepted).
  final Set<String> accepted;

  /// Row uuids the server refused outright. These will be retried; a row that
  /// is permanently unacceptable would otherwise wedge the queue forever, which
  /// is why [rejected] is surfaced rather than swallowed.
  final Set<String> rejected;

  /// Row uuids the server flagged as conflicting, for the owner's resolution
  /// screen. Treated as accepted for watermark purposes — the server has them.
  final Set<String> conflicts;

  const PushResult({
    this.accepted = const {},
    this.rejected = const {},
    this.conflicts = const {},
  });

  bool get isEmpty => accepted.isEmpty && rejected.isEmpty && conflicts.isEmpty;
}

/// The wire, behind an interface (the same shape Plan 001 used for
/// `BackupTarget`).
///
/// Two reasons this is not just the HTTP client. It lets the engine be driven
/// end-to-end in a test by a fake relay — two real databases converging through
/// an in-memory server is the only way to prove the merge rules actually
/// converge, and no amount of mocking one device proves that. And it keeps the
/// engine free of HTTP concerns, so retry/backoff/auth live in one place.
abstract class SyncTransport {
  /// Send local changes. Implementations must be safe to call with a batch that
  /// was already sent — the per-row idempotency key makes a repeat a no-op.
  Future<PushResult> push(List<SyncChange> changes);

  /// Fetch one page of changes after [since].
  Future<PullPage> pull({required int since, int limit});
}
