import 'package:drift/drift.dart';
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
        ..where((c) => c.isArchived.equals(false))
        ..orderBy([(c) => OrderingTerm(expression: c.name)]))
      .get();

  Future<CustomerRow?> getCustomer(String id) =>
      (select(customers)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// Insert or replace by id (used for both add and edit).
  Future<void> upsertCustomer(CustomersCompanion customer) =>
      into(customers).insert(customer, mode: InsertMode.insertOrReplace);

  Future<int> deleteCustomer(String id) =>
      (delete(customers)..where((c) => c.id.equals(id))).go();

  /// How many ledger entries a customer has — used to guard deletion.
  Future<int> countEntries(String customerId) async {
    final counter = countAll();
    final row = await (selectOnly(ledgerEntries)
          ..addColumns([counter])
          ..where(ledgerEntries.customerId.equals(customerId)))
        .getSingle();
    return row.read(counter) ?? 0;
  }

  /// Reactive list of non-archived customers, each with derived balance
  /// (`charge` as +, `payment` as −), entry count and last activity. One
  /// grouped LEFT JOIN so a customer with no entries still shows (balance 0).
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
      LEFT JOIN ledger_entries l ON l.customer_id = c.id
      WHERE c.is_archived = 0
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
