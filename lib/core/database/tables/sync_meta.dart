import 'package:drift/drift.dart';

/// Sync bookkeeping shared by every table that replicates between devices
/// (Plan 002, Phase 0).
///
/// Mixed into a table rather than repeated nine times, so a change to the sync
/// contract is one edit and no table can quietly drift out of step.
///
/// All three default to `''` (the codebase's existing "absent" convention —
/// same as `product_units.soldInvoiceId`), which is what makes adding them a
/// purely additive migration: every existing row decodes as "never synced,
/// never deleted, origin unknown", which is exactly true.
mixin SyncMeta on Table {
  /// Packed [Hlc] of the last change to this row — the **authorship** clock,
  /// used to resolve last-write-wins.
  ///
  /// Deliberately *not* the sync cursor: the server stamps its own monotonic
  /// sequence on arrival, and ordering conflicts by arrival would let a device
  /// that was offline for three days overwrite fresher edits. Text because the
  /// packed form sorts lexicographically in clock order, so plain SQL
  /// comparison works.
  ///
  /// `''` means "predates sync" — treated as older than any real stamp, so a
  /// legacy row never beats a real edit.
  TextColumn get updatedAt => text().withDefault(const Constant(''))();

  /// Tombstone: packed [Hlc] of the deletion, `''` while the row is live.
  ///
  /// Synced rows are **never physically deleted**. Without a tombstone, "absent
  /// here, present there" is ambiguous — never-synced or deliberately deleted? —
  /// and the merge would resurrect the row from the other device on the next
  /// pull. A shopkeeper deleting a product and watching it reappear is the
  /// single most corrosive sync bug, because it makes the whole feature look
  /// untrustworthy.
  TextColumn get deletedAt => text().withDefault(const Constant(''))();

  /// Device that authored the row's current state.
  ///
  /// Doubles as the audit trail. Because the shops running two devices are
  /// staffed by partners and relatives, the product decision was to make
  /// changes *visible* rather than forbidden — no permission system, but the
  /// owner can always see which device changed a price. Relaying a row must
  /// preserve this value, never overwrite it with the forwarding device.
  TextColumn get originDevice => text().withDefault(const Constant(''))();
}
