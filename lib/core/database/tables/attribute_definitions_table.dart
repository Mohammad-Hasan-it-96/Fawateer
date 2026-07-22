import 'package:drift/drift.dart';

/// Owner-defined custom product fields (Plan 010, bucket A) — the *metadata*
/// that drives the dynamic product form, list subtitle, and receipt printing.
/// The per-product values live in `products.attributes` (JSON), keyed by [id].
///
/// Purely additive table (schema v12→v13); no existing table is touched.
@DataClassName('AttributeDefinitionRow')
class AttributeDefinitions extends Table {
  TextColumn get id => text()();
  // The owner-typed label (user data, Arabic) — editable without orphaning
  // stored values, which are keyed by id, not label.
  TextColumn get label => text()();
  // AttributeType name ('text' | 'number' | 'select' | 'boolean' | 'date').
  // Stored by name (not index) — unknown/legacy decodes to 'text'.
  TextColumn get type => text().withDefault(const Constant('text'))();
  // JSON string array of choices for 'select' types; '' otherwise.
  TextColumn get options => text().withDefault(const Constant(''))();
  TextColumn get unit => text().withDefault(const Constant(''))();
  BoolColumn get isRequired => boolean().withDefault(const Constant(false))();
  BoolColumn get showInList => boolean().withDefault(const Constant(false))();
  BoolColumn get showOnReceipt => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
