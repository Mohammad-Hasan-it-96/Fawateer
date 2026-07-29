/// A device's role within its sync business (ADR 0011).
///
/// The only asymmetry is **ownership of the subscription**, not a permission
/// matrix: every device is an equal peer for business data (any device sells,
/// edits products, takes payments). The owner additionally mints/revokes join
/// tokens and manages the plan. Persisted **by name** (never index), matching the
/// app's convention for every stored enum, so the server's `owner`/`member`
/// strings map straight across.
enum SyncSeatRole {
  owner,
  member;

  static SyncSeatRole fromName(String? name) {
    return SyncSeatRole.values.firstWhere(
      (r) => r.name == name,
      orElse: () => SyncSeatRole.member,
    );
  }

  bool get isOwner => this == SyncSeatRole.owner;
}
