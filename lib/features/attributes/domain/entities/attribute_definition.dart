import 'package:equatable/equatable.dart';

import 'attribute_type.dart';

/// One owner-defined custom product field (Plan 010, bucket A).
///
/// This is the *metadata* that drives the dynamic product form, the product
/// list subtitle, and receipt printing. The actual per-product value lives in
/// `ProductAttributes` keyed by [id] (never by [label] — so renaming a label
/// never orphans data). One row per field in the `attribute_definitions` table.
class AttributeDefinition extends Equatable {
  /// Stable key the product value map is keyed by. Immutable once created.
  final String id;

  /// The label the owner typed — **user data** (e.g. "اللون", "IMEI"), shown in
  /// forms/receipts. Editable without touching stored product values.
  final String label;

  final AttributeType type;

  /// Choices for [AttributeType.select]; empty otherwise.
  final List<String> options;

  /// Optional display suffix (e.g. `GB`, `ml`, `V`).
  final String unit;

  /// Blocks saving a *product* when empty (never blocks a sale).
  final bool isRequired;

  /// Whether this field shows in the product-list subtitle.
  final bool showInList;

  /// Whether this field prints on invoices/labels (snapshotted at sale time).
  final bool showOnReceipt;

  /// Form/field ordering.
  final int sortOrder;

  /// Soft-hide: kept off forms but preserved on existing products/receipts.
  final bool isArchived;

  const AttributeDefinition({
    required this.id,
    required this.label,
    this.type = AttributeType.text,
    this.options = const [],
    this.unit = '',
    this.isRequired = false,
    this.showInList = false,
    this.showOnReceipt = false,
    this.sortOrder = 0,
    this.isArchived = false,
  });

  AttributeDefinition copyWith({
    String? id,
    String? label,
    AttributeType? type,
    List<String>? options,
    String? unit,
    bool? isRequired,
    bool? showInList,
    bool? showOnReceipt,
    int? sortOrder,
    bool? isArchived,
  }) {
    return AttributeDefinition(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      options: options ?? this.options,
      unit: unit ?? this.unit,
      isRequired: isRequired ?? this.isRequired,
      showInList: showInList ?? this.showInList,
      showOnReceipt: showOnReceipt ?? this.showOnReceipt,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  List<Object?> get props => [
        id,
        label,
        type,
        options,
        unit,
        isRequired,
        showInList,
        showOnReceipt,
        sortOrder,
        isArchived,
      ];
}
