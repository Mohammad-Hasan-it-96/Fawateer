import 'package:equatable/equatable.dart';

/// A subscription plan offered by the server (monthly / 6-month / annual …).
/// Plan-agnostic: duration and pricing come straight from the catalog so adding
/// a new plan server-side needs no client change.
class SubscriptionPlan extends Equatable {
  final String id;
  final String title;
  final String description;
  final int durationMonths;
  final double price;

  /// Discounted price when the server offers one; null means no discount.
  final double? priceAfterDiscount;

  final bool enabled;
  final bool recommended;
  final String currencyCode;
  final String currencySymbol;

  const SubscriptionPlan({
    required this.id,
    required this.title,
    this.description = '',
    required this.durationMonths,
    required this.price,
    this.priceAfterDiscount,
    this.enabled = true,
    this.recommended = false,
    this.currencyCode = '',
    this.currencySymbol = '',
  });

  double get effectivePrice => priceAfterDiscount ?? price;

  bool get hasDiscount =>
      priceAfterDiscount != null && priceAfterDiscount! < price;

  /// What a plan request echoes back so the operator knows what was asked for.
  ///
  /// The server's own [id] whenever it sent one. The duration-derived fallback
  /// below cannot identify a plan: two plans of the same length (a "12 months
  /// Basic" and a "12 months Pro") both encode to `12_months`, leaving the
  /// operator unable to tell which one the customer requested — and any plan
  /// that isn't a whole number of months (lifetime, a 45-day promo) has no
  /// honest encoding at all.
  ///
  /// The fallback keeps Smart-Agent's `<n>_months` convention for a catalogue
  /// served without ids, so an older/leaner server still gets a readable label.
  String get requestedPlanCode => id.isNotEmpty
      ? id
      : '${durationMonths}_month${durationMonths == 1 ? '' : 's'}';

  factory SubscriptionPlan.fromJson(
    Map<String, dynamic> json, {
    String currencyCode = '',
    String currencySymbol = '',
  }) {
    return SubscriptionPlan(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      durationMonths: _toInt(json['duration_months']),
      price: _toDouble(json['price']),
      priceAfterDiscount: json['price_after_discount'] == null
          ? null
          : _toDouble(json['price_after_discount']),
      enabled: _toBool(json['enabled'], fallback: true),
      recommended: _toBool(json['recommended']),
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
    );
  }

  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  static double _toDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

  static bool _toBool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return fallback;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        durationMonths,
        price,
        priceAfterDiscount,
        enabled,
        recommended,
        currencyCode,
        currencySymbol,
      ];
}
