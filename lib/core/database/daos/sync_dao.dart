import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../features/sync/domain/entities/sync_change.dart';
import '../app_database.dart';
import '../sync_tables.dart';
import '../tables/products_table.dart';
import '../tables/stock_movements_table.dart';

part 'sync_dao.g.dart';

/// Reads local changes out of, and writes remote changes into, the replicated
/// tables (Plan 002, Phase 1).
///
/// **Deliberately generic — no per-table serializers.** A row's payload is just
/// its column map, read with `SELECT *` and written back column by column. Nine
/// hand-written mappers would be nine places to forget a column, and the one
/// that gets forgotten is silently *not replicated* — a price that updates on
/// one phone and not the other, with nothing in the code to point at. The cost
/// is that the SQL is assembled at runtime, so every identifier is checked
/// against the live schema before it is used (see [_columnsOf]).
///
/// `Products` and `StockMovements` are in the accessor list so the post-apply
/// quantity rebuild can name `products` as an updated table — the
/// `customUpdate(..., updates:)` rule that makes `watchAllProducts` re-run.
@DriftAccessor(tables: [Products, StockMovements])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  /// Column names of [table], as the database actually has them.
  ///
  /// Every dynamically-built statement filters through this. The payload keys
  /// come off the wire, so this is the boundary that stops an unexpected key
  /// reaching SQL as an identifier — and it doubles as forward compatibility: a
  /// newer device sending a column this build does not have is ignored rather
  /// than fatal.
  Future<Set<String>> _columnsOf(String table) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return rows.map((r) => r.read<String>('name')).toSet();
  }

  /// The `NOT NULL` columns of [table], split by whether a null arriving for
  /// them can be repaired.
  ///
  /// **A null on the wire for a `NOT NULL` column is an artifact, not data**,
  /// and the app has to survive it. evotech-core runs Laravel's default
  /// `ConvertEmptyStringsToNull` middleware, which rewrites every empty string
  /// in a request to null — **recursively, through arrays**. Our push payload is
  /// a nested array of the row's columns, so every `''` in it (`deleted_at` on a
  /// live row, `related_id`, `note`, a blank barcode) arrived as null, was stored
  /// as null, and was handed back to the other phone as null.
  ///
  /// That is not a survivable crash: `applyChanges` runs in one transaction, so
  /// a single such row aborts the whole page, the pull cursor never advances,
  /// and the next pass re-reads the same page and fails identically. The device
  /// is wedged permanently with no way out but a re-seed. Found on 2026-08-31 —
  /// a stock edit on the second phone, `NOT NULL constraint failed:
  /// stock_movements.deleted_at`, on every sync from then on.
  ///
  /// [text] is repaired to `''`, which is exactly the value the sender had:
  /// `''` is the only thing that middleware turns into null, so the round trip
  /// is lossless. [other] cannot be repaired that way — a null for a NOT NULL
  /// integer was never an empty string, so there is nothing to restore — and the
  /// key is dropped instead, letting the column default apply on insert and the
  /// local value stand on update.
  ///
  /// [mandatory] is the NOT NULL columns with **no default**, and it is why
  /// dropping alone is not enough: `stock_movements.occurred_at` is
  /// `INTEGER NOT NULL` with nothing to fall back to, so an insert missing it
  /// fails exactly as loudly as the null would have. A row that cannot supply
  /// one is unwritable, and is skipped — the same rule
  /// [SyncChange.fromJson] already applies to a malformed row, for the same
  /// reason: one bad row in a page must not wedge the device forever. An update
  /// is unaffected, since the existing row already holds a value.
  ///
  /// The server should also stop mangling an opaque payload (its `TrimStrings`
  /// still silently strips a deliberate leading space from a product name, which
  /// this cannot detect or undo) — but the client must not depend on that.
  Future<({Set<String> text, Set<String> other, Set<String> mandatory})>
      _notNullOf(String table) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    final text = <String>{};
    final other = <String>{};
    final mandatory = <String>{};
    for (final r in rows) {
      if (r.read<int>('notnull') == 0) continue;
      final name = r.read<String>('name');
      if (r.read<String?>('dflt_value') == null) mandatory.add(name);
      // SQLite type affinity: TEXT/CHAR/CLOB all store strings. Read loosely
      // because the declared type is whatever the migration wrote.
      final type = (r.read<String?>('type') ?? '').toUpperCase();
      if (type.contains('CHAR') ||
          type.contains('TEXT') ||
          type.contains('CLOB')) {
        text.add(name);
      } else {
        other.add(name);
      }
    }
    return (text: text, other: other, mandatory: mandatory);
  }

  /// Local rows changed since [sinceHlc], oldest change first, across every
  /// replicated table.
  ///
  /// The watermark is the **authored** HLC, not a timestamp and not a row
  /// count: it is the only value that is monotonic on this device and
  /// comparable as plain text (`updated_at > ?` works because the packed form
  /// sorts in clock order — that is why it is padded).
  ///
  /// Rows with `updated_at = ''` are skipped. Those predate sync entirely: a
  /// shop that has been trading for a year has thousands of them, and pushing
  /// that history row-by-row on first enrollment would be both enormous and
  /// pointless — the bootstrap snapshot carries it instead (ADR 0011 Decision
  /// 13). They start replicating the moment anything touches them.
  ///
  /// Only rows **this device authored** ([originDevice]) are collected. An
  /// applied remote row carries the author's HLC, which is normally *above* our
  /// watermark — so without this filter every device pushes straight back
  /// everything it has just received. The server deduplicates it by idempotency
  /// key so nothing breaks, but two tills would spend every sync tick echoing
  /// each other's traffic. Nothing is lost by not relaying: a row we did not
  /// author reached us from the server, so the server already has it.
  Future<List<SyncChange>> collectSince(
    String sinceHlc, {
    required String originDevice,
    int limit = 500,
  }) async {
    final out = <SyncChange>[];
    for (final spec in kSyncTables) {
      if (out.length >= limit) break;
      final columns = await _columnsOf(spec.table);
      if (!columns.contains('updated_at')) continue;

      final rows = await customSelect(
        'SELECT * FROM ${spec.table} '
        "WHERE updated_at != '' AND updated_at > ? AND origin_device = ? "
        'ORDER BY updated_at ASC LIMIT ?',
        variables: [
          Variable<String>(sinceHlc),
          Variable<String>(originDevice),
          Variable<int>(limit - out.length),
        ],
      ).get();

      for (final row in rows) {
        final data = Map<String, dynamic>.from(row.data);
        final rowUuid = data[spec.syncId]?.toString();
        if (rowUuid == null || rowUuid.isEmpty) continue;
        final deletedAt = data['deleted_at']?.toString() ?? '';
        for (final local in spec.localOnly) {
          data.remove(local);
        }
        out.add(SyncChange(
          table: spec.table,
          rowUuid: rowUuid,
          op: deletedAt.isEmpty ? SyncChange.opUpsert : SyncChange.opDelete,
          payload: data,
          authoredHlc: data['updated_at']?.toString() ?? '',
          originDevice: data['origin_device']?.toString() ?? '',
        ));
      }
    }
    // Ordered across tables by authorship, so a batch that is truncated at
    // [limit] is truncated at a point in time rather than mid-table — the
    // remainder is simply "everything after this HLC" on the next pass.
    out.sort((a, b) => a.authoredHlc.compareTo(b.authoredHlc));
    return out.length > limit ? out.sublist(0, limit) : out;
  }

  /// The highest `updated_at` present locally, i.e. the watermark a device
  /// should start from when it has never pushed but has already been seeded.
  ///
  /// Used after a bootstrap restore: the snapshot arrives holding the owner's
  /// rows *with their stamps*, and pushing all of them straight back would be a
  /// pointless round trip of data the server already has.
  Future<String> highestLocalHlc() async {
    var best = '';
    for (final spec in kSyncTables) {
      final columns = await _columnsOf(spec.table);
      if (!columns.contains('updated_at')) continue;
      final row = await customSelect(
              "SELECT MAX(updated_at) AS m FROM ${spec.table} WHERE updated_at != ''")
          .getSingle();
      final m = row.data['m']?.toString() ?? '';
      if (m.compareTo(best) > 0) best = m;
    }
    return best;
  }

  /// Apply a batch of inbound changes, in one transaction.
  ///
  /// Returns how many actually changed something — a page that is entirely
  /// echoes of our own pushes applies nothing, and the caller wants to know
  /// that rather than report "42 changes received".
  ///
  /// Conflict resolution is **last-write-wins on the authored HLC**, evaluated
  /// per row. An incoming change is applied only if it is strictly newer than
  /// what is here; equal loses, which is what makes re-applying an echo of our
  /// own push a no-op and makes the whole operation idempotent.
  Future<int> applyChanges(List<SyncChange> changes) async {
    if (changes.isEmpty) return 0;

    return transaction(() async {
      var applied = 0;
      final productsToRebuild = <String>{};

      // Grouped and ordered by kSyncTables so parents land before children —
      // an invoice's lines must never be visible before the invoice.
      for (final spec in kSyncTables) {
        final forTable = changes.where((c) => c.table == spec.table);
        if (forTable.isEmpty) continue;
        final columns = await _columnsOf(spec.table);
        final notNull = await _notNullOf(spec.table);

        for (final change in forTable) {
          final payload = <String, dynamic>{};
          for (final entry in change.payload.entries) {
            if (spec.localOnly.contains(entry.key)) continue;
            if (!columns.contains(entry.key)) continue; // unknown/newer column
            var value = entry.value;
            if (value == null) {
              // See [_notNullOf]: a null here is a relayed empty string, not a
              // value. Repair it, or drop the key — never let it reach SQLite,
              // where it aborts the transaction and wedges the device.
              if (notNull.text.contains(entry.key)) {
                value = '';
              } else if (notNull.other.contains(entry.key)) {
                continue;
              }
            }
            payload[entry.key] = value;
          }
          // The identity must survive the filtering, or the row would be
          // written with no way to find it again.
          payload[spec.syncId] = change.rowUuid;

          final existing = await customSelect(
            'SELECT updated_at FROM ${spec.table} WHERE ${spec.syncId} = ?',
            variables: [Variable<String>(change.rowUuid)],
          ).getSingleOrNull();

          if (existing != null) {
            final localHlc = existing.data['updated_at']?.toString() ?? '';
            // Strictly newer, or the remote loses. Equal is an echo of
            // something we already have.
            if (change.authoredHlc.compareTo(localHlc) <= 0) continue;
            final sets = payload.keys.where((k) => k != spec.syncId).toList();
            if (sets.isEmpty) continue;
            await customUpdate(
              'UPDATE ${spec.table} SET ${sets.map((c) => '$c = ?').join(', ')} '
              'WHERE ${spec.syncId} = ?',
              variables: [
                ...sets.map((c) => _variable(payload[c])),
                Variable<String>(change.rowUuid),
              ],
              updates: {products},
            );
          } else {
            // An insert has to supply every NOT NULL column that has no
            // default. If the wire did not carry one there is nothing to
            // invent, so the row is skipped rather than allowed to abort the
            // page — see [_notNullOf].
            // `localOnly` is excluded: those columns are deliberately never
            // sent and the database supplies them. `sales_items.id` is the
            // case — an autoincrement rowid alias, NOT NULL with no default,
            // which is exactly the shape this check looks for. Without the
            // exclusion every replicated sale line is silently skipped, which
            // is how this was caught: two invoices arrived with no lines.
            final missing = notNull.mandatory.where(
                (c) => !payload.containsKey(c) && !spec.localOnly.contains(c));
            if (missing.isNotEmpty) {
              if (kDebugMode) {
                debugPrint('[sync] skipped ${spec.table}/${change.rowUuid}: '
                    'missing required ${missing.toList()}');
              }
              continue;
            }
            final cols = payload.keys.toList();
            await customInsert(
              'INSERT INTO ${spec.table} (${cols.join(', ')}) '
              'VALUES (${List.filled(cols.length, '?').join(', ')})',
              variables: cols.map((c) => _variable(payload[c])).toList(),
              updates: {products},
            );
          }
          applied++;

          if (kQuantityAffectingTables.contains(spec.table)) {
            final productId = change.payload['product_id']?.toString();
            if (productId != null && productId.isNotEmpty) {
              productsToRebuild.add(productId);
            }
          }
        }
      }

      // On-hand is derived but stored. Without this the other device's sale is
      // in the log and the number on screen is unchanged, which reads as "sync
      // did nothing".
      for (final productId in productsToRebuild) {
        await customUpdate(
          kRecomputeQuantitySql,
          variables: [Variable<String>(productId)],
          updates: {products},
        );
      }
      return applied;
    });
  }

  /// Fires whenever anything in a replicated table changes, so a sale can reach
  /// the other till in seconds rather than on the next timer tick.
  ///
  /// Note this also fires for changes *we just applied* from a pull. That is a
  /// self-trigger, not a loop: the pass it provokes finds nothing of ours to
  /// push (see [collectSince]) and nothing new to pull, so it settles after one
  /// extra round. Debouncing in the scheduler keeps that round cheap.
  Stream<void> watchLocalChanges() {
    final names = kSyncTables.map((s) => s.table).toSet();
    return attachedDatabase.tableUpdates().where((updates) {
      return updates.any((u) => names.contains(u.table));
    }).map((_) {});
  }

  /// Bind a JSON scalar as the right SQLite type.
  ///
  /// JSON has no integer/real distinction that survives a round trip, and drift
  /// needs a typed variable. Booleans arrive as `true`/`false` from a JSON
  /// encoder but SQLite stores them as 0/1, so they are normalised here rather
  /// than in every caller.
  static Variable _variable(dynamic value) {
    if (value == null) return const Variable<String>(null);
    if (value is bool) return Variable<int>(value ? 1 : 0);
    if (value is int) return Variable<int>(value);
    if (value is double) return Variable<double>(value);
    if (value is num) return Variable<double>(value.toDouble());
    return Variable<String>(value.toString());
  }
}
