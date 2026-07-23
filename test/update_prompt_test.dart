import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:billing_app/core/config/remote_config.dart';
import 'package:billing_app/core/config/remote_config_service.dart';
import 'package:billing_app/core/config/update_dialog.dart';
import 'package:billing_app/l10n/app_localizations.dart';

/// Regression tests for the "published 1.0.1 but no update prompt" bug.
///
/// The update checker wraps `MaterialApp.router` via `builder:`, so its own
/// context sits *above* the router's Navigator. `showDialog` from that context
/// throws "no Navigator ancestor" — silently, inside a post-frame future — so
/// the prompt never appeared on any device. The fix routes the dialog through
/// `rootNavigatorKey.currentContext` (the router's Navigator).
void main() {
  RemoteConfigService serviceWithUpdate() {
    final service = RemoteConfigService();
    service.current = const RemoteConfig(
      latestVersion: '9.9.9',
      baseUrl: '',
      downloads: {'arm64-v8a': 'https://example.com/app.apk'},
      updateNotes: ['ملاحظة تجريبية'],
      supportEmail: '',
      supportWhatsApp: '',
      supportTelegram: '',
    );
    service.updateAvailable = true;
    service.downloadUrl = 'https://example.com/app.apk';
    return service;
  }

  Widget appShell({
    required GlobalKey<NavigatorState> navKey,
    required void Function(BuildContext builderContext) onFirstFrame,
  }) {
    final router = GoRouter(
      navigatorKey: navKey,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('home')),
        ),
      ],
    );
    return MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Same structure as the app: the checker lives in `builder:`.
      builder: (context, child) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => onFirstFrame(context));
        return child ?? const SizedBox.shrink();
      },
    );
  }

  testWidgets('builder context has no Navigator — the original bug',
      (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    BuildContext? builderContext;
    await tester.pumpWidget(appShell(
      navKey: navKey,
      onFirstFrame: (context) => builderContext = context,
    ));
    await tester.pump();

    // Navigator.of from the builder's context throws — which is exactly what
    // showDialog does internally, and why the prompt never surfaced.
    expect(() => Navigator.of(builderContext!), throwsFlutterError);
  });

  testWidgets('showUpdateDialog via the root navigator key shows the dialog',
      (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    final service = serviceWithUpdate();
    await tester.pumpWidget(appShell(
      navKey: navKey,
      // The fix: dialogs opened from above the router go through the
      // navigator's own context, never the builder's.
      onFirstFrame: (_) =>
          showUpdateDialog(navKey.currentContext!, service),
    ));
    await tester.pumpAndSettle();

    expect(find.text('يتوفر تحديث جديد'), findsOneWidget); // dialog title
    expect(find.text('• ملاحظة تجريبية'), findsOneWidget); // release note
    expect(find.text('تحميل التحديث'), findsOneWidget); // download button
  });
}
