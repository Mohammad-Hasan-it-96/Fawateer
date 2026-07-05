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

  /// Duration encoded for the backend's operator request. Matches Smart-Agent's
  /// `<n>_months` convention and adds `1_month` for the monthly plan.
  String get requestedPlanCode =>
      '${durationMonths}_month${durationMonths == 1 ? '' : 's'}';

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
