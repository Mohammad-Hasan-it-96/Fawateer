import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../../../core/database/daos/settings_dao.dart';
import '../../../core/notifications/local_notifier.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/product.dart';
import '../domain/low_stock_alert.dart';
import '../domain/repositories/product_repository.dart';

/// Tell the shop when something runs down to its alert level (Plan 013 #10).
///
/// **This app does no background work, and that is a decision, not a gap** —
/// same as `AutoBackupService` and the sync scheduler, for the same reasons
/// (Android background limits, OEM task-killers, the support cost of both). So:
///
/// > An alert can only appear **while the app is open**. It cannot arrive at
/// > 9pm with the app closed.
///
/// That is still worth having, because stock only ever moves *inside* this app:
/// the moment a sale takes the last packet below the line is a moment the
/// cashier is holding the phone. Nothing can change while it is closed, so
/// nothing is missed — only delayed until the shop next opens it.
///
/// Off by default. A shop sets `minStockAlert` to colour the product list, and
/// inheriting notifications from that would be a surprise; the toggle in
/// Settings is where they actually ask for them.
class LowStockNotifier {
  final ProductRepository _repository;
  final SettingsDao _settings;
  final LocalNotifier _notifier;
  final Locale _locale;

  LowStockNotifier(
    this._repository,
    this._settings,
    this._notifier, {
    required Locale locale,
  }) : _locale = locale;

  static const String enabledKey = 'low_stock_alerts_enabled';

  /// The ids already reported, as a JSON list. Absent (never written) is
  /// meaningfully different from empty — see [_onProducts].
  static const String announcedKey = 'low_stock_announced';

  /// One notification id, reused on purpose: a later alert **replaces** the
  /// earlier one instead of stacking. A shop that sells all afternoon should
  /// find one current notice in the tray, not fourteen.
  static const int _notificationId = 91001;

  StreamSubscription<List<Product>>? _sub;

  Future<bool> isEnabled() async =>
      await _settings.getValue(enabledKey) == 'true';

  /// Turn alerts on or off.
  ///
  /// Switching **on** seeds the baseline with whatever is already low and does
  /// not announce it. "Tell me when something runs low" is a request about the
  /// future; replaying the current backlog as a notification would be a list,
  /// and the Reports page already has that (Plan 013 #1).
  Future<void> setEnabled(bool value) async {
    await _settings.setValue(enabledKey, value.toString());
    if (value) {
      final products = await _repository.watchProducts().first;
      await _writeAnnounced(lowStockIds(products));
      start();
    } else {
      await stop();
    }
  }

  /// Begin watching. Safe to call repeatedly; does nothing while disabled.
  Future<void> start() async {
    if (_sub != null) return;
    if (!await isEnabled()) return;
    _sub = _repository.watchProducts().listen(
          _onProducts,
          // A broken stock stream must not take the app down over an alert.
          onError: (_) {},
        );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> _onProducts(List<Product> products) async {
    final raw = await _settings.getValue(announcedKey);
    if (raw == null) {
      // First run after the feature landed: take the current state as the
      // baseline rather than announcing a catalogue's worth of history.
      await _writeAnnounced(lowStockIds(products));
      return;
    }
    final announced = _decode(raw);
    final fresh = newlyLowIds(products, announced);
    final stillLow = lowStockIds(products);

    // Only write when the set actually moved. This stream re-emits on every
    // sale, and a database write per scan would be pure waste.
    if (!_sameSet(stillLow, announced)) {
      await _writeAnnounced(stillLow);
    }
    if (fresh.isEmpty) return;

    final justLow = products.where((p) => fresh.contains(p.id)).toList();
    await _show(justLow);
  }

  Future<void> _show(List<Product> justLow) async {
    // Loaded without a BuildContext — a service has none, and the alert must
    // still speak the app's language.
    final l10n = await AppLocalizations.delegate.load(_locale);
    final names = justLow.map((p) => p.name).toList();
    if (justLow.length == 1) {
      final p = justLow.first;
      await _notifier.show(
        id: _notificationId,
        title: l10n.lowStockAlertOne(p.name),
        body: l10n.lowStockAlertRemaining(formatQty(p.quantity)),
      );
      return;
    }
    await _notifier.show(
      id: _notificationId,
      title: l10n.lowStockAlertMany(justLow.length),
      // Three names is enough to recognise the situation; a tray notice that
      // lists twenty is unreadable and gets swiped away unread.
      body: names.length <= 3
          ? names.join('، ')
          : '${names.take(3).join('، ')} …',
    );
  }

  Future<void> _writeAnnounced(Set<String> ids) =>
      _settings.setValue(announcedKey, jsonEncode(ids.toList()));

  /// Defensive: a corrupted or hand-edited value reads as "nothing announced"
  /// rather than throwing inside a stream listener.
  static Set<String> _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return {};
      return decoded.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}
