import 'package:billing_app/features/licensing/domain/entities/subscription_plan.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure entity logic — no network, no plugins.
void main() {
  SubscriptionPlan plan({String id = '', int months = 12}) => SubscriptionPlan(
        id: id,
        title: 't',
        description: '',
        durationMonths: months,
        price: 100,
      );

  group('requestedPlanCode', () {
    test('prefers the server plan id', () {
      expect(plan(id: 'pro_12').requestedPlanCode, 'pro_12');
    });

    test('distinguishes two plans of the same duration', () {
      // The whole point of the change: the duration-derived fallback collapses
      // these two into one string, so the operator cannot tell them apart.
      final basic = plan(id: 'basic_12', months: 12);
      final pro = plan(id: 'pro_12', months: 12);
      expect(basic.requestedPlanCode, isNot(pro.requestedPlanCode));
    });

    test('falls back to <n>_months when the server sent no id', () {
      expect(plan(months: 12).requestedPlanCode, '12_months');
    });

    test('fallback singularises the monthly plan', () {
      expect(plan(months: 1).requestedPlanCode, '1_month');
    });
  });

  group('fromJson', () {
    test('carries the id through so it can be echoed back', () {
      final p = SubscriptionPlan.fromJson(const {
        'id': 'pro_12',
        'title': 'Pro',
        'duration_months': 12,
        'price': 100,
      });
      expect(p.id, 'pro_12');
      expect(p.requestedPlanCode, 'pro_12');
    });

    test('a catalogue served without ids still yields a usable code', () {
      final p = SubscriptionPlan.fromJson(const {
        'title': 'Yearly',
        'duration_months': 12,
        'price': 100,
      });
      expect(p.id, '');
      expect(p.requestedPlanCode, '12_months');
    });
  });
}
