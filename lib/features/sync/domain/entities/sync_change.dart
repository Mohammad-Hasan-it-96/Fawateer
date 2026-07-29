import 'package:equatable/equatable.dart';

/// One replicated row change, in the wire shape agreed with the backend
/// (`docs/backend-replies/`, ADR 0011 Decision 9).
///
/// Deliberately **opaque about columns**: [payload] is the row's own column map,
/// carried straight through. The server stores it as JSON in `device_changes`
/// and never interprets it (except for the few materialized arbitration tables
/// it maintains for conflict detection), so adding a column to a synced table
/// needs no server change and no version negotiation — a device on an older
/// build simply ignores keys it does not have.
class SyncChange extends Equatable {
  /// SQLite table name.
  final String table;

  /// The row's cross-device identity — see `SyncTableSpec.syncId`.
  final String rowUuid;

  /// `upsert` or `delete`.
  ///
  /// Informational for the applier, which upserts either way: a tombstone is a
  /// normal row with `deleted_at` set, and the payload already carries it. The
  /// field exists because the server indexes on it and the owner's conflict
  /// screen reads it.
  final String op;

  /// The row's columns. For a delete this is still the whole row, tombstone
  /// included — the receiving device needs the marker, not an absence.
  final Map<String, dynamic> payload;

  /// The packed HLC the authoring device stamped. **This is what resolves
  /// last-write-wins**, never the server's arrival order: a device that was
  /// offline for three days pushes changes that arrive last but were authored
  /// first, and ordering by arrival would let them overwrite fresher edits.
  final String authoredHlc;

  /// The node that authored this state. Preserved verbatim on relay — a device
  /// forwarding someone else's row must not stamp itself as the author, or the
  /// audit trail ("which device changed this price") silently becomes wrong.
  final String originDevice;

  /// Server-assigned per-business sequence. Absent on outbound changes; set on
  /// inbound ones, and the thing the pull cursor advances through.
  final int? seq;

  const SyncChange({
    required this.table,
    required this.rowUuid,
    required this.op,
    required this.payload,
    required this.authoredHlc,
    required this.originDevice,
    this.seq,
  });

  static const String opUpsert = 'upsert';
  static const String opDelete = 'delete';

  bool get isDelete => op == opDelete;

  /// Per-row idempotency key (§F2 of the 2026-07-28 reply).
  ///
  /// Per **row**, never per batch: partial success is normal on push, and a
  /// batch-level key would already be consumed on a retry, so the rows the
  /// server rejected would be silently dropped. Row uuid + authored HLC means a
  /// re-push of the same edit is byte-identical and no-ops, while a *later* edit
  /// to the same row carries a different HLC and is correctly a new change.
  String get idempotencyKey => '$rowUuid:$authoredHlc';

  Map<String, dynamic> toJson() => {
        'table_name': table,
        'row_uuid': rowUuid,
        'op': op,
        'payload': payload,
        'authored_hlc': authoredHlc,
        'origin_device': originDevice,
        'idempotency_key': idempotencyKey,
      };

  /// Parse an inbound change. Returns null for anything malformed rather than
  /// throwing: one bad row in a page of 500 must not abort the whole sync and
  /// strand the device, and the cursor still advances past it.
  static SyncChange? fromJson(Map<String, dynamic> json) {
    final table = json['table_name']?.toString();
    final rowUuid = json['row_uuid']?.toString();
    final payload = json['payload'];
    if (table == null || table.isEmpty) return null;
    if (rowUuid == null || rowUuid.isEmpty) return null;
    if (payload is! Map) return null;

    final seq = json['seq'];
    return SyncChange(
      table: table,
      rowUuid: rowUuid,
      op: json['op']?.toString() ?? opUpsert,
      payload: Map<String, dynamic>.from(payload),
      authoredHlc: json['authored_hlc']?.toString() ?? '',
      originDevice: json['origin_device']?.toString() ?? '',
      seq: seq is int ? seq : int.tryParse('$seq'),
    );
  }

  @override
  List<Object?> get props =>
      [table, rowUuid, op, authoredHlc, originDevice, seq];
}
