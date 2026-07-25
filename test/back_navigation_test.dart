import 'package:billing_app/config/routes/app_shell.dart';
import 'package:billing_app/features/licensing/domain/repositories/license_repository.dart';
import 'package:billing_app/features/licensing/presentation/bloc/license_bloc.dart';
import 'package:billing_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Android back-button handling in the tab shell.
///
/// The reported bug: back on any tab root killed the app instantly — a cashier
/// mid-sale lost the screen to one stray thumb tap. The shell now swallows that
/// press, but the delicate part is that it must **only** swallow presses the
/// tab branches didn't already consume: a pushed page has to keep popping
/// normally. These tests pin both halves.
class _FakeLicenseRepository implements LicenseRepository {
  // No event is ever dispatched to the bloc here, so nothing is called on it;
  // the shell's banners just read the initial state.
  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

void main() {
  /// Simulates the Android system back button, exactly as the engine delivers
  /// it — not `Navigator.pop`, which would bypass the PopScope under test.
  Future<void> pressSystemBack(WidgetTester tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec()
          .encodeMethodCall(const MethodCall('popRoute')),
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  /// Records `SystemNavigator.pop()` — i.e. "the app actually closed". Only
  /// that call is kept; MaterialApp chatters on the same channel
  /// (`SystemChrome.setApplicationSwitcherDescription`) and would drown it out.
  late List<String> exitCalls;

  setUp(() {
    exitCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemNavigator.pop') exitCalls.add(call.method);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/pos',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/pos',
                builder: (_, __) => const Text('POS'),
                routes: [
                  GoRoute(
                      path: 'checkout',
                      builder: (_, __) => const Text('CHECKOUT')),
                ],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/products',
                builder: (_, __) => const Text('PRODUCTS'),
                routes: [
                  GoRoute(
                      path: 'add', builder: (_, __) => const Text('ADD')),
                ],
              ),
            ]),
          ],
        ),
      ],
    );

    return BlocProvider<LicenseBloc>(
      create: (_) => LicenseBloc(repository: _FakeLicenseRepository()),
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      ),
    );
  }

  testWidgets('a pushed page still pops normally — the shell must not eat it',
      (tester) async {
    // The regression this guards: intercepting back at the shell level could
    // swallow presses meant for a pushed page, trapping the cashier on
    // "add product" with no way back.
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    tester.element(find.text('POS')).findAncestorWidgetOfExactType<Scaffold>();
    final router = GoRouter.of(tester.element(find.text('POS')));
    router.go('/products/add');
    await tester.pumpAndSettle();
    expect(find.text('ADD'), findsOneWidget);

    await pressSystemBack(tester);

    expect(find.text('PRODUCTS'), findsOneWidget,
        reason: 'back should pop the pushed page, not jump tabs');
    expect(exitCalls, isEmpty, reason: 'the app must not close');
  });

  testWidgets('back on a non-POS tab root returns to the POS tab',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.text('POS')));
    router.go('/products');
    await tester.pumpAndSettle();
    expect(find.text('PRODUCTS'), findsOneWidget);

    await pressSystemBack(tester);

    expect(find.text('POS'), findsOneWidget,
        reason: 'back from another tab means "go home", not "quit"');
    expect(exitCalls, isEmpty);
  });

  testWidgets('back on the POS tab warns first, then exits on a second press',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // First press: warn, stay open. This is the whole point — one stray tap
    // must never close the till mid-sale.
    await pressSystemBack(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(find.text(l10n.pressBackAgainToExit), findsOneWidget);
    expect(exitCalls, isEmpty, reason: 'one press must not exit');

    // Second press inside the window: now it really closes.
    await pressSystemBack(tester);
    expect(exitCalls, contains('SystemNavigator.pop'));
  });

  testWidgets('a lone back press long after the warning does not exit',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await pressSystemBack(tester);
    expect(exitCalls, isEmpty);

    // Window closed: the next press starts over rather than quitting, so a
    // back press now and another one minutes later can't add up to an exit.
    await tester.pump(const Duration(seconds: 5));
    await pressSystemBack(tester);
    expect(exitCalls, isEmpty,
        reason: 'the two presses must be consecutive to count');
  });
}
