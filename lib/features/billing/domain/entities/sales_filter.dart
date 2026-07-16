import 'package:equatable/equatable.dart';

/// Quick date ranges for the audit center. [custom] uses an explicit
/// from/to picked by the user. [last7Days]/[last30Days] are rolling windows
/// used by the analytics dashboard (Plan 008).
enum DatePreset {
  today,
  yesterday,
  last7Days,
  last30Days,
  thisWeek,
  thisMonth,
  custom,
}

/// Payment-type filter. Cash vs credit is derived (see [InvoiceListItem]).
enum PaymentFilter { all, cash, credit }

/// List ordering.
enum SalesSort { newest, oldest, highest, lowest }

/// The full, resolved query behind the Sales History screen. Holds an already
/// resolved [from]/[to] range (inclusive, millisecond-precise day bounds) plus
/// the payment filter, free-text search, and sort. Build new filters with the
/// `with*` helpers so the date range stays consistent with the preset.
class SalesFilter extends Equatable {
  final DatePreset preset;
  final DateTime from;
  final DateTime to;
  final PaymentFilter payment;
  final String search;
  final SalesSort sort;

  const SalesFilter({
    required this.preset,
    required this.from,
    required this.to,
    this.payment = PaymentFilter.all,
    this.search = '',
    this.sort = SalesSort.newest,
  });

  /// Default when the screen first opens: today's sales, newest first.
  factory SalesFilter.initial() {
    final (from, to) = resolveRange(DatePreset.today);
    return SalesFilter(preset: DatePreset.today, from: from, to: to);
  }

  SalesFilter withPreset(DatePreset preset) {
    final (from, to) = resolveRange(preset);
    return copyWith(preset: preset, from: from, to: to);
  }

  SalesFilter withCustomRange(DateTime from, DateTime to) {
    final (f, t) = resolveRange(DatePreset.custom, customFrom: from, customTo: to);
    return copyWith(preset: DatePreset.custom, from: f, to: t);
  }

  SalesFilter withPayment(PaymentFilter payment) => copyWith(payment: payment);
  SalesFilter withSort(SalesSort sort) => copyWith(sort: sort);
  SalesFilter withSearch(String search) => copyWith(search: search);

  /// Resolve a preset (or a custom from/to) to inclusive day bounds. The `to`
  /// bound is end-of-day (23:59:59.999) so a `BETWEEN from AND to` in epoch-ms
  /// includes every sale made that day. Weeks start on **Saturday** (regional
  /// convention for the Arabic-first UI).
  static (DateTime, DateTime) resolveRange(
    DatePreset preset, {
    DateTime? customFrom,
    DateTime? customTo,
  }) {
    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    switch (preset) {
      case DatePreset.today:
        return (startToday, _endOfDay(now));
      case DatePreset.yesterday:
        final y = startToday.subtract(const Duration(days: 1));
        return (y, _endOfDay(y));
      case DatePreset.last7Days:
        // Rolling 7-day window including today (today + previous 6 days).
        return (startToday.subtract(const Duration(days: 6)), _endOfDay(now));
      case DatePreset.last30Days:
        return (startToday.subtract(const Duration(days: 29)), _endOfDay(now));
      case DatePreset.thisWeek:
        // Days elapsed since the most recent Saturday (Sat→0 … Fri→6).
        final backToSaturday = (now.weekday + 1) % 7;
        final start = startToday.subtract(Duration(days: backToSaturday));
        return (start, _endOfDay(now));
      case DatePreset.thisMonth:
        return (DateTime(now.year, now.month, 1), _endOfDay(now));
      case DatePreset.custom:
        final f = customFrom ?? startToday;
        final t = customTo ?? now;
        return (DateTime(f.year, f.month, f.day), _endOfDay(t));
    }
  }

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  SalesFilter copyWith({
    DatePreset? preset,
    DateTime? from,
    DateTime? to,
    PaymentFilter? payment,
    String? search,
    SalesSort? sort,
  }) {
    return SalesFilter(
      preset: preset ?? this.preset,
      from: from ?? this.from,
      to: to ?? this.to,
      payment: payment ?? this.payment,
      search: search ?? this.search,
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => [preset, from, to, payment, search, sort];
}
