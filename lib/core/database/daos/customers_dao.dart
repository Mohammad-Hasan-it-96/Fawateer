import 'package:drift/drift.dart';
import '../../sync/sync_clock.dart';
import '../app_database.dart';
import '../tables/customers_table.dart';
import '../tables/ledger_entries_table.dart';

part 'customers_dao.g.dart';

/// A customer joined with their DERIVED balance and activity summary — computed
/// in one grouped query (no N+1). Plain fields (not a generated row) to keep the
/// repository mapping independent of Drift's generated constructors.
class CustomerBalanceRow {
  final String id;
  final String name;
  final String phone;
  final String note;
  final int createdAt;
  final double balance;
  final int entryCount;
  final int? lastEntryAt;

  const CustomerBalanceRow({
    required this.id,
    required this.name,
    required this.phone,
    required this.note,
    required this.createdAt,
    required this.balance,
    required this.entryCount,
    required this.lastEntryAt,
  });
}

@DriftAccessor(tables: [Customers, LedgerEntries])
class CustomersDao extends DatabaseAccessor<AppDatabase>
    with _$CustomersDaoMixin {
  CustomersDao(super.db);

  Future<List<CustomerRow>> getAllCustomers() => (select(customers)
        ..where((c) => c.isArchived.equals(false) & c.deletedAt.equals(''))
        ..orderBy([(c) => OrderingTerm(expression: c.name)]))
      .get();

  Future<CustomerRow?> getCustomer(String id) => (select(customers)
        ..where((c) => c.id.equals(id) & c.deletedAt.equals('')))
      .getSingleOrNull();

  /// Reactive single customer — emits on every edit so a detail view stays live.
  ///
  /// Emits `null` once the customer is tombstoned, which is what closes an open
  /// detail page when the delete arrives from another device.
  Stream<CustomerRow?> watchCustomer(String id) => (select(customers)
        ..where((c) => c.id.equals(id) & c.deletedAt.equals('')))
      .watchSingleOrNull();

  /// Whether a non-archived customer already has this [name], compared
  /// case-insensitively and trimmed. Pass [exceptId] to ignore one customer
  /// (the one being edited) so saving without a name change isn't a conflict.
  ///
  /// Tombstoned rows do not count: a shop that deleted "أبو أحمد" must be able
  /// to add that name again, and the deleted row is invisible everywhere else.
  Future<bool> nameExists(String name, {String? exceptId}) async {
    final needle = name.trim().toLowerCase();
    final query = select(customers)
      ..where((c) =>
          c.name.lower().equals(needle) &
          c.isArchived.equals(false) &
          c.deletedAt.equals(''));
    if (exceptId != null) {
      query.where((c) => c.id.equals(exceptId).not());
    }
    final rows = await query.get();
    return rows.isNotEmpty;
  }

  /// Insert or replace by id (used for both add and edit).
  Future<void> upsertCustomer(CustomersCompanion customer) =>
      into(customers).insert(customer, mode: InsertMode.insertOrReplace);

  /// Tombstone a customer. See `ProductsDao.softDeleteProduct` for why the
  /// predicate excludes already-deleted rows.
  Future<int> softDeleteCustomer(String id, SyncStamp stamp) =>
      (update(customers)
            ..where((c) => c.id.equals(id) & c.deletedAt.equals('')))
          .write(CustomersCompanion(
        deletedAt: Value(stamp.hlc),
        updatedAt: Value(stamp.hlc),
        originDevice: Value(stamp.device),
      ));

  /// How many ledger entries a customer has — used to guard deletion.
  ///
  /// Counts live entries only. A customer whose entries were all deleted is
  /// deletable, which matches what the shopkeeper sees: an empty statement.
  Future<int> countEntries(String customerId) async {
    final counter = countAll();
    final row = await (selectOnly(ledgerEntries)
          ..addColumns([counter])
          ..where(ledgerEntries.customerId.equals(customerId) &
              ledgerEntries.deletedAt.equals('')))
        .getSingle();
    return row.read(counter) ?? 0;
  }

  /// Reactive list of non-archived customers, each with derived balance
  /// (`charge` as +, `payment` as −), entry count and last activity. One
  /// grouped LEFT JOIN so a customer with no entries still shows (balance 0).
  ///
  /// The ledger tombstone filter lives in the **ON clause, not the WHERE** — in
  /// the WHERE it would turn the LEFT JOIN into an inner join and drop every
  /// customer who has no live entries, which is precisely the customer the
  /// LEFT JOIN exists to keep.
  Stream<List<CustomerBalanceRow>> watchCustomersWithBalance() {
    final query = customSelect(
      '''
      SELECT c.id AS id, c.name AS name, c.phone AS phone, c.note AS note,
             c.created_at AS created_at,
             COALESCE(SUM(CASE WHEN l.entry_type = 'charge'
                               THEN l.amount ELSE -l.amount END), 0.0) AS balance,
             COUNT(l.id) AS entry_count,
             MAX(l.created_at) AS last_entry_at
      FROM customers c
      LEFT JOIN ledger_entries l
             ON l.customer_id = c.id AND l.deleted_at = ''
      WHERE c.is_archived = 0 AND c.deleted_at = ''
      GROUP BY c.id
      ORDER BY c.name COLLATE NOCASE
      ''',
      readsFrom: {customers, ledgerEntries},
    );
    return query.watch().map((rows) => rows.map((r) {
          final d = r.data;
          return CustomerBalanceRow(
            id: d['id'] as String,
            name: d['name'] as String,
            phone: (d['phone'] ?? '') as String,
            note: (d['note'] ?? '') as String,
            createdAt: d['created_at'] as int,
            balance: (d['balance'] as num).toDouble(),
            entryCount: d['entry_count'] as int,
            lastEntryAt: d['last_entry_at'] as int?,
          );
        }).toList());
  }
}
