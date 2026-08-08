// The oversold-stock card (Plan 002 Q6) renders.
//
// A widget test because what can go wrong here is presentational: the stored
// figure is negative and the shopkeeper is shown a shortfall, and the app is
// Arabic-first RTL.
import 'package:billing_app/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:billing_app/features/dashboard/presentation/widgets/stock_conflict_card.dart';
import 'package:billing_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Locale locale, List<NamedAmount> items) => MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: StockConflictCard(items: items)),
    );

void main() {
  for (final locale in const [Locale('ar'), Locale('en')]) {
    testWidgets('locale ${locale.languageCode}: a shortfall reads as positive',
        (tester) async {
      await tester.pumpWidget(_host(locale, const [
        NamedAmount(name: 'Rice', amount: -3),
        NamedAmount(name: 'Sugar', amount: -1.5),
      ]));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(locale);
      expect(find.text('Rice'), findsOneWidget);
      // The stored value is negative; "short 3" is the number the shopkeeper
      // counts against on the shelf. "-3" would read as a price or a loss.
      expect(find.text(l10n.stockConflictShort('3')), findsOneWidget);
      expect(find.text(l10n.stockConflictShort('1.5')), findsOneWidget);

      // The copy has to say nothing was lost. An owner seeing a shortfall
      // assumes a sale went missing — the opposite of what happened.
      expect(find.text(l10n.stockConflictBody), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('there is no resolve button', (tester) async {
    await tester.pumpWidget(
        _host(const Locale('ar'), const [NamedAmount(name: 'Rice', amount: -3)]));
    await tester.pumpAndSettle();

    // Deliberate: tapping something to make the number go away would falsify a
    // count nobody has checked. The fix is a stock take, in the world.
    expect(find.byType(ButtonStyleButton), findsNothing);
  });

  test('an empty list is not a section that says "all clear"', () {
    // The view keys on this. A card that sits there permanently reading "no
    // problems" is one the owner stops seeing, which costs it exactly the
    // attention it exists to get.
    expect(const DashboardData().hasStockConflicts, isFalse);
    expect(
      const DashboardData(oversold: [NamedAmount(name: 'Rice', amount: -3)])
          .hasStockConflicts,
      isTrue,
    );
  });
}
