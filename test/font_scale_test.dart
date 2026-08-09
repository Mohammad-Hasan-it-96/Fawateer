// The app-wide text-size ladder (Plan 011 #1, extended with `tiny`).
import 'package:billing_app/core/theme/font_scale_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the options are ordered smallest to largest', () {
    // The settings sheet renders `AppFontScale.values` in order and previews
    // each at its own size. Declaring one out of order would show the owner a
    // ladder that goes down in the middle.
    final factors = AppFontScale.values.map((s) => s.factor).toList();
    for (var i = 1; i < factors.length; i++) {
      expect(factors[i], greaterThan(factors[i - 1]),
          reason: '${AppFontScale.values[i].name} is out of order');
    }
  });

  test('tiny is the floor, and still readable', () {
    expect(AppFontScale.values.first, AppFontScale.tiny);
    // Below ~0.8 the shop's own product names stop being readable across a
    // counter — the cure would be worse than the cramped screen.
    expect(AppFontScale.tiny.factor, greaterThanOrEqualTo(0.8));
  });

  test('normal is exactly 1.0', () {
    // Anything else silently rescales every screen for a shop that never opened
    // this setting.
    expect(AppFontScale.normal.factor, 1.0);
  });
}
