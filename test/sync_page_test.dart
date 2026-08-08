// The multi-device screen renders (Plan 002).
//
// A widget test rather than more BLoC coverage, because the failures this
// catches are layout ones: the app is Arabic-first RTL, the join code is opaque
// ASCII that RTL will happily reorder, and the QR is drawn by a CustomPainter
// that has to survive a dark theme.
import 'package:billing_app/features/sync/data/sync_state_store.dart';
import 'package:billing_app/features/sync/domain/entities/join_invite.dart';
import 'package:billing_app/features/sync/domain/entities/join_token.dart';
import 'package:billing_app/features/sync/domain/entities/sync_device.dart';
import 'package:billing_app/features/sync/domain/entities/sync_device_registry.dart';
import 'package:billing_app/features/sync/domain/entities/sync_seat_role.dart';
import 'package:billing_app/features/sync/domain/entities/sync_session.dart';
import 'package:billing_app/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:billing_app/features/sync/presentation/pages/sync_page.dart';
import 'package:billing_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Publishes states directly, so the page can be pinned in each of its shapes
/// without driving the whole enrollment flow.
class _StubSyncBloc extends Bloc<SyncEvent, SyncState> implements SyncBloc {
  _StubSyncBloc(super.initialState) {
    on<SyncEvent>((_, __) {});
  }

  void push(SyncState state) => emit(state);
}

Widget _host(Locale locale, _StubSyncBloc bloc) => MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<SyncBloc>.value(value: bloc, child: const SyncPage()),
    );

/// The button carrying [label], found by walking up from its text.
///
/// `find.byType(FilledButton)` matches the exact runtime type, and
/// `FilledButton.icon` builds a private subclass — so a byType lookup finds
/// nothing at all here.
FilledButton _buttonWith(WidgetTester tester, String label) =>
    tester.widget<FilledButton>(find
        .ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate((w) => w is FilledButton),
        )
        .first);

const _owner = SyncSession(
  syncToken: 't',
  businessUuid: 'b',
  seatUuid: 's',
  role: SyncSeatRole.owner,
  deviceAllowance: 3,
);

void main() {
  for (final locale in const [Locale('ar'), Locale('en')]) {
    group('locale ${locale.languageCode}', () {
      testWidgets('an unenrolled device gets the pitch, not a blank screen',
          (tester) async {
        final bloc = _StubSyncBloc(const SyncState(loaded: true));
        await tester.pumpWidget(_host(locale, bloc));
        await tester.pumpAndSettle();

        final l10n = await AppLocalizations.delegate.load(locale);
        expect(find.text(l10n.syncPitchTitle), findsOneWidget);
        expect(find.text(l10n.syncEnableAction), findsOneWidget);
        expect(find.text(l10n.syncJoinAction), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('an enrolled owner sees status and can add a phone',
          (tester) async {
        final bloc =
            _StubSyncBloc(const SyncState(loaded: true, session: _owner));
        await tester.pumpWidget(_host(locale, bloc));
        await tester.pumpAndSettle();

        final l10n = await AppLocalizations.delegate.load(locale);
        expect(find.text(l10n.syncStatusOwner), findsOneWidget);
        expect(find.text(l10n.syncAddDeviceAction), findsOneWidget);
        expect(find.text(l10n.syncNowAction), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('an offline owner is told the limit, never a used-count',
          (tester) async {
        final bloc =
            _StubSyncBloc(const SyncState(loaded: true, session: _owner));
        await tester.pumpWidget(_host(locale, bloc));
        await tester.pumpAndSettle();

        final l10n = await AppLocalizations.delegate.load(locale);
        // No registry: "0 of 3 phones used" would be a statement about a shop
        // that may well have three linked phones.
        expect(find.text(l10n.syncDevicesAllowed(3)), findsOneWidget);
        expect(find.text(l10n.syncDevicesUsed(0, 3)), findsNothing);
        // And nothing is gated on information we do not have.
        expect(_buttonWith(tester, l10n.syncAddDeviceAction).onPressed,
            isNotNull);
      });

      testWidgets('an owner at their cap sees why, and Add is disabled',
          (tester) async {
        final bloc = _StubSyncBloc(const SyncState(
          loaded: true,
          session: _owner,
          registry: SyncDeviceRegistry(
            allowance: 2,
            devices: [
              SyncDevice(uuid: 's', role: SyncSeatRole.owner, isCurrent: true),
              SyncDevice(uuid: 's2', role: SyncSeatRole.member),
            ],
          ),
        ));
        await tester.pumpWidget(_host(locale, bloc));
        await tester.pumpAndSettle();

        final l10n = await AppLocalizations.delegate.load(locale);
        expect(find.text(l10n.syncDevicesUsed(2, 2)), findsOneWidget);
        // Disabled, not hidden: "add a phone" vanishing is what an owner at
        // their cap reads as the feature being broken, and the reason given is
        // something they can act on.
        expect(_buttonWith(tester, l10n.syncAddDeviceAction).onPressed, isNull);
        expect(find.text(l10n.syncAtCapHint(2)), findsOneWidget);
      });

      testWidgets('a linked phone is never told a device allowance of zero',
          (tester) async {
        final bloc = _StubSyncBloc(const SyncState(
          loaded: true,
          session: SyncSession(
            syncToken: 't',
            businessUuid: 'b',
            seatUuid: 's2',
            role: SyncSeatRole.member,
            // What a member join actually stores — the allowance belongs to the
            // business and is only ever sent to the owner.
            deviceAllowance: 0,
          ),
        ));
        await tester.pumpWidget(_host(locale, bloc));
        await tester.pumpAndSettle();

        final l10n = await AppLocalizations.delegate.load(locale);
        expect(find.text(l10n.syncStatusMemberHint), findsOneWidget);
        expect(find.text(l10n.syncDevicesAllowed(0)), findsNothing);
      });

      testWidgets('a linked phone is not offered the owner-only action',
          (tester) async {
        final bloc = _StubSyncBloc(const SyncState(
          loaded: true,
          session: SyncSession(
            syncToken: 't',
            businessUuid: 'b',
            seatUuid: 's2',
            role: SyncSeatRole.member,
            deviceAllowance: 3,
          ),
        ));
        await tester.pumpWidget(_host(locale, bloc));
        await tester.pumpAndSettle();

        final l10n = await AppLocalizations.delegate.load(locale);
        expect(find.text(l10n.syncStatusMember), findsOneWidget);
        // The server would refuse it; offering it is worse than hiding it.
        expect(find.text(l10n.syncAddDeviceAction), findsNothing);
      });

      testWidgets('the join code renders as a QR and as typable text',
          (tester) async {
        final bloc = _StubSyncBloc(SyncState(
          loaded: true,
          session: _owner,
          invite: JoinInvite(
            token: JoinToken(
              token: 'JOIN-ABC-123',
              expiresAt: DateTime.now().add(const Duration(minutes: 9)),
            ),
            snapshotSha256: 'abc123',
          ),
        ));
        await tester.pumpWidget(_host(locale, bloc));
        await tester.pumpAndSettle();

        // Both, always: a phone with a cracked lens still has to be able to
        // join, which is why there is a typed fallback at all.
        final code = find.byWidgetPredicate(
            (w) => w is SelectableText && w.data == 'JOIN-ABC-123');
        expect(code, findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);

        // Forced LTR — an opaque ASCII code reordered by the Arabic layout gets
        // typed back in wrongly on the other phone.
        expect(tester.widget<SelectableText>(code).textDirection,
            TextDirection.ltr);
        expect(tester.takeException(), isNull);
      });

      testWidgets('an expired code says so instead of showing a dead QR',
          (tester) async {
        final bloc = _StubSyncBloc(SyncState(
          loaded: true,
          session: _owner,
          invite: JoinInvite(
            token: JoinToken(
              token: 'OLD',
              expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
            ),
          ),
        ));
        await tester.pumpWidget(_host(locale, bloc));
        await tester.pumpAndSettle();

        final l10n = await AppLocalizations.delegate.load(locale);
        expect(find.text(l10n.syncJoinCodeExpired), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('the page holds a spinner until the first read lands',
      (tester) async {
    // Not a cosmetic detail: without it an enrolled device flashes the
    // "turn this on" pitch for a frame every time the page opens.
    final bloc = _StubSyncBloc(const SyncState());
    await tester.pumpWidget(_host(const Locale('ar'), bloc));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('a dark theme does not swallow the QR', (tester) async {
    final bloc = _StubSyncBloc(SyncState(
      loaded: true,
      session: _owner,
      invite: JoinInvite(
        token: JoinToken(
          token: 'JOIN-1',
          expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        ),
      ),
    ));
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      locale: const Locale('ar'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<SyncBloc>.value(value: bloc, child: const SyncPage()),
    ));
    await tester.pumpAndSettle();

    // The QR sits on an explicit white plate. A dark-on-dark QR renders
    // perfectly and scans on nothing.
    final plate = tester.widgetList<Container>(find.byType(Container)).where(
        (c) => c.color == Colors.white);
    expect(plate, isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  test('SyncStateStore keys are stable', () {
    // Renaming one silently resets every device's position: it would re-pull
    // the shop's history and re-push its own.
    expect(SyncStateStore.kPushWatermark, 'sync_push_watermark');
    expect(SyncStateStore.kPullCursor, 'sync_pull_cursor');
    expect(SyncStateStore.kLastSyncAt, 'sync_last_at');
  });
}
