// The customer statement rendered as a shareable card (Plan 013 #8).
//
// A widget test because the risks here are presentational and financial at the
// same time: the card is a document a customer will read and argue with. The
// app is Arabic-first RTL, and the row list is capped — a truncation that is
// not announced would have the customer counting rows and finding money
// missing.
import 'package:billing_app/core/share/cards/customer_statement_share_card.dart';
import 'package:billing_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Locale locale, Widget card) => MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: card)),
    );

CustomerStatementShareCard _card(
  AppLocalizations l10n, {
  List<StatementShareLine> lines = const [],
  int omitted = 0,
  double balance = 0,
  double charges = 0,
  double payments = 0,
}) =>
    CustomerStatementShareCard(
      l10n: l10n,
      currency: 'ل.س',
      shopName: 'محل الأمل',
      customerName: 'أحمد العلي',
      customerPhone: '0933123456',
      dateText: '2026/08/08',
      lines: lines,
      omittedCount: omitted,
      totalCharges: charges,
      totalPayments: payments,
      balance: balance,
    );

void main() {
  for (final locale in const [Locale('ar'), Locale('en')]) {
    testWidgets('locale ${locale.languageCode}: the card renders a statement',
        (tester) async {
      final l10n = await AppLocalizations.delegate.load(locale);
      await tester.pumpWidget(_host(
        locale,
        _card(l10n,
            charges: 50000,
            payments: 20000,
            balance: 30000,
            lines: [
              StatementShareLine(
                  dateText: '2026/07/01',
                  label: l10n.entryDebt,
                  amount: 50000,
                  isCharge: true),
              StatementShareLine(
                  dateText: '2026/07/20',
                  label: l10n.entryPayment,
                  amount: 20000,
                  isCharge: false,
                  note: 'دفعة أولى'),
            ]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('محل الأمل'), findsOneWidget);
      expect(find.text('أحمد العلي'), findsOneWidget);
      // Charges and payments read in opposite directions; a sign that is wrong
      // on a debt document is the one mistake nobody forgives.
      expect(find.textContaining('+'), findsWidgets);
      expect(find.textContaining('-'), findsWidgets);
      // A note the shopkeeper wrote is part of the record.
      expect(find.text('دفعة أولى'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a truncated statement says how many entries are missing',
      (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    await tester.pumpWidget(_host(
      const Locale('ar'),
      _card(l10n, omitted: 12, balance: 1000, charges: 1000),
    ));
    await tester.pumpAndSettle();

    // Silent truncation is the failure mode this line exists to prevent.
    expect(find.text(l10n.statementMoreEntries(12)), findsOneWidget);
  });

  testWidgets('a complete statement shows no truncation line', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    await tester.pumpWidget(_host(const Locale('ar'), _card(l10n)));
    await tester.pumpAndSettle();

    expect(find.text(l10n.statementMoreEntries(0)), findsNothing);
  });

  testWidgets('a settled account says settled, not zero', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    await tester.pumpWidget(_host(
      const Locale('ar'),
      _card(l10n, charges: 5000, payments: 5000),
    ));
    await tester.pumpAndSettle();

    // "0" is a number; "settled" is the answer the customer came for.
    expect(find.text(l10n.balanceSettled), findsOneWidget);
  });

  testWidgets('a customer in credit is not shown as owing', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    await tester.pumpWidget(_host(
      const Locale('ar'),
      _card(l10n, balance: -4000, payments: 4000),
    ));
    await tester.pumpAndSettle();

    // A negative balance means the shop owes the customer. Labelling that as a
    // debt would be an accusation.
    expect(find.text(l10n.balanceCreditLabel), findsOneWidget);
    expect(find.text(l10n.balanceOwedLabel), findsNothing);
  });
}
