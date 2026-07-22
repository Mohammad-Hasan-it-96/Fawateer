import 'dart:convert';

import 'package:equatable/equatable.dart';

/// The custom-attribute values carried by one product (Plan 010, bucket A).
///
/// A thin immutable wrapper over `Map<String, String>` where the key is an
/// `AttributeDefinition.id` and the value is the raw **display string** the
/// owner entered (numbers/dates/booleans are kept as their string form — see
/// [AttributeType]). Kept as strings deliberately: simple shops don't need typed
/// JSON, and one string map round-trips, prints, and searches trivially.
///
/// This is the single source of truth, persisted as a JSON object in
/// `products.attributes`. All parsing is centralized here and is **defensive**:
/// a null/blank/garbled column decodes to [empty] and never throws (same posture
/// as `NumInput.parseFlexibleNumber` and the by-name enum `fromName` fallbacks),
/// so no downstream screen can crash on legacy or corrupt data.
class ProductAttributes extends Equatable {
  /// Unmodifiable map of definitionId → value. Empty values are never stored.
  final Map<String, String> values;

  const ProductAttributes._(this.values);

  static const empty = ProductAttributes._({});

  factory ProductAttributes(Map<String, String> values) {
    final cleaned = <String, String>{};
    values.forEach((key, value) {
      final k = key.trim();
      final v = value.trim();
      if (k.isNotEmpty && v.isNotEmpty) cleaned[k] = v;
    });
    return cleaned.isEmpty ? empty : ProductAttributes._(Map.unmodifiable(cleaned));
  }

  bool get isEmpty => values.isEmpty;
  bool get isNotEmpty => values.isNotEmpty;

  /// The stored value for a definition id, or null if unset.
  String? operator [](String definitionId) => values[definitionId];

  /// Returns a copy with [value] set for [definitionId]; a blank value clears it.
  ProductAttributes withValue(String definitionId, String value) {
    final next = Map<String, String>.from(values);
    if (value.trim().isEmpty) {
      next.remove(definitionId);
    } else {
      next[definitionId] = value.trim();
    }
    return ProductAttributes(next);
  }

  /// Decode from the stored JSON column. Any error → [empty] (never throws).
  factory ProductAttributes.fromJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) return empty;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return empty;
      final map = <String, String>{};
      decoded.forEach((key, value) {
        if (value != null) map[key.toString()] = value.toString();
      });
      return ProductAttributes(map);
    } catch (_) {
      return empty;
    }
  }

  /// Encode for the DB column. Empty → `''` (so the column stays blank, matching
  /// the additive default and keeping "no attributes" cheap to detect).
  String toJson() => isEmpty ? '' : jsonEncode(values);

  @override
  List<Object?> get props => [values];
}
