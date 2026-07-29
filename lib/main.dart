import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/routes/app_routes.dart';
import 'core/config/remote_config_service.dart';
import 'core/config/update_dialog.dart';
import 'core/service_locator.dart' as di;
import 'core/sync/sync_clock.dart';
import 'core/sync/sync_identity.dart';
import 'features/sync/data/sync_scheduler.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/font_scale_controller.dart';
import 'core/theme/theme_controller.dart';
import 'features/backup/data/auto_backup_service.dart';
import 'features/billing/presentation/bloc/billing_bloc.dart';
import 'features/billing/presentation/bloc/history_bloc.dart';
import 'features/product/presentation/bloc/product_bloc.dart';
import 'features/attributes/presentation/bloc/attribute_definition_bloc.dart';
import 'features/shop/presentation/bloc/shop_bloc.dart';
import 'features/settings/presentation/bloc/printer_bloc.dart';
import 'features/settings/presentation/bloc/printer_event.dart';
import 'features/licensing/presentation/bloc/license_bloc.dart';
import 'features/licensing/data/services/device_identity_service.dart';
import 'features/licensing/data/services/push_notification_service.dart';
import 'features/ledger/presentation/bloc/customer_bloc.dart';
import 'features/cashbox/presentation/bloc/cashbox_bloc.dart';
import 'l10n/app_localizations.dart';

/// Lets the FCM foreground handler surface an in-app banner from outside the
/// widget tree (no BuildContext at the callsite). Dormant unless FCM is enabled.
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Portrait only, both ways up. Mirrored by `android:screenOrientation` in
  // AndroidManifest.xml — see the comment there for why it's locked twice.
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );
  // Load locale data (Arabic month names, ص/م) for intl's DateFormat.
  await initializeDateFormatting();
  await di.init();

  // Load the remote config (fawateer_version.json) — applies the API base URL
  // and support contacts, and flags an available update. Await it briefly so an
  // overridden base URL is in place before the first license call, but cap the
  // wait so a slow network can't stall startup; it finishes in the background
  // either way (the update-checker widget awaits the same shared future).
  try {
    await di
        .sl<RemoteConfigService>()
        .ensureLoaded()
        .timeout(const Duration(seconds: 4));
  } catch (_) {/* keep going; the config applies once it lands */}

  // Adopt this device's sync identity and restore the logical clock before any
  // screen can write (Plan 002, Phase 0). Awaited rather than fired off: a
  // delete taken before this lands would stamp its tombstone with an empty node
  // id, which unpacks as malformed and would lose the delete on the next merge.
  // `getDeviceId` is already bounded by its own 3s channel timeout and never
  // throws, so this cannot stall startup the way the config fetch can.
  await di
      .sl<SyncClock>()
      .load(syncNodeId(await di.sl<DeviceIdentityService>().getDeviceId()));

  // Read the stored light/dark preference before the first frame, so the app
  // doesn't paint light and then flip. Local DB read; never throws.
  await di.sl<ThemeController>().load();
  // Same for the app-wide font-size preference (Plan 011 #1).
  await di.sl<FontScaleController>().load();

  runApp(const MyApp());

  // Start FCM live-unlock (fire-and-forget; self-disables without Firebase
  // config). A license-related push re-checks the subscription on the shared
  // LicenseBloc, so the router gate unlocks the app the instant the operator
  // activates the device — no restart needed. If it arrives while the app is
  // open, also show a visible banner (background/terminated get a tray notice).
  di.sl<PushNotificationService>().initialize(
        onLicenseChanged: () => di.sl<LicenseBloc>().add(CheckLicenseEvent()),
        onForegroundLicenseChange: _showSubscriptionActivatedBanner,
        // The sync doorbell. Silent — the shopkeeper sees the other till's sale
        // appear, not a notification that one is coming.
        onSyncChanged: () => di.sl<SyncScheduler>().onRemoteChange(),
      );

  // Multi-device sync triggers (Plan 002, Phase 1). Started after runApp and
  // deliberately NOT awaited: it fires a pass on launch, and blocking the first
  // frame on a network round trip is exactly the startup cost this app has
  // avoided everywhere else. It short-circuits immediately on a device with no
  // seat, which is most of them.
  unawaited(di.sl<SyncScheduler>().start());
}

void _showSubscriptionActivatedBanner() {
  final messenger = rootMessengerKey.currentState;
  final context = rootMessengerKey.currentContext;
  if (messenger == null || context == null) return;
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return;
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(l10n.subscriptionActivatedBanner),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 5),
      ),
    );
}

/// Awaits the shared remote-config load, then shows a one-time update dialog if
/// a newer version is published. Non-blocking and dismissible ("Later").
class _UpdateChecker extends StatefulWidget {
  const _UpdateChecker({required this.child});
  final Widget child;

  @override
  State<_UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<_UpdateChecker>
    with WidgetsBindingObserver {
  bool _prompted = false;

  /// Quiet post-startup retry, armed only when the startup fetch never reached
  /// the network (device opened offline / network came up after launch).
  /// Cancelled the moment one network fetch succeeds.
  Timer? _retryTimer;
  static const _retryInterval = Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybePrompt();
      // Launch is the main backup opportunity: the shop opens the app every
      // morning. Fire-and-forget — it decides for itself whether one is due.
      di.sl<AutoBackupService>().maybeRun();
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Also on resume, so a device left running for days still backs up daily.
    if (state == AppLifecycleState.resumed) {
      di.sl<AutoBackupService>().maybeRun();
      // Coming back to the app is the natural moment connectivity has changed
      // (user toggled wifi, walked into coverage) — retry immediately rather
      // than waiting out the timer.
      if (!di.sl<RemoteConfigService>().networkResolved) _retryCheck();
    }
  }

  Future<void> _maybePrompt() async {
    final service = di.sl<RemoteConfigService>();
    await service.ensureLoaded();
    if (!mounted || _prompted) return;
    if (service.updateAvailable) {
      await _showPrompt(service);
      return;
    }
    // No update *seen* — but if the startup fetch never reached the network,
    // that's inconclusive, not a verdict. Keep retrying quietly until one
    // fetch succeeds; startup itself was never blocked on this (the awaited
    // load in main() is capped at 4s and this all runs after the first frame).
    if (!service.networkResolved) {
      _retryTimer ??= Timer.periodic(_retryInterval, (_) => _retryCheck());
    }
  }

  Future<void> _retryCheck() async {
    final service = di.sl<RemoteConfigService>();
    await service.refresh();
    if (!mounted) return;
    if (!service.networkResolved) return; // still offline — keep the timer
    _retryTimer?.cancel();
    _retryTimer = null;
    if (_prompted || !service.updateAvailable) return;
    await _showPrompt(service);
  }

  Future<void> _showPrompt(RemoteConfigService service) async {
    // Wait for the license gate to settle first. Until `bootstrapped`, the
    // router is on the splash and about to swap the whole page stack
    // (splash → shell/activation); a dialog pushed before that swap rides on
    // the splash page and is silently disposed with it (pageless routes die
    // with the page they're attached to). Verified on device: the dialog
    // appeared during the splash and was killed ~2s later by the redirect.
    final licenseBloc = di.sl<LicenseBloc>();
    if (!licenseBloc.state.bootstrapped) {
      await licenseBloc.stream.firstWhere((s) => s.bootstrapped);
    }
    // Let the gate's redirect navigation + page transition finish so the
    // dialog attaches to the destination page, not the outgoing splash.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted || _prompted) return;

    // MUST use the router's navigator context, not this widget's own: this
    // widget wraps `MaterialApp.router` via `builder:`, so its context sits
    // *above* the Navigator — `showDialog` from it throws "no Navigator
    // ancestor", silently, inside a post-frame future. This was why the very
    // first published update (1.0.1) never showed its prompt.
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return; // navigator not built yet; retry lands it
    _prompted = true;
    // Safe across the async gap above: navContext is fetched *fresh* from the
    // GlobalKey after every await, never captured before one.
    // ignore: use_build_context_synchronously
    await showUpdateDialog(navContext, service);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // LicenseBloc is a shared singleton (also read by the router gate), so
        // provide the existing instance rather than creating a new one.
        BlocProvider<LicenseBloc>.value(
            value: di.sl<LicenseBloc>()..add(CheckLicenseEvent())),
        BlocProvider<ProductBloc>(
            create: (context) => di.sl<ProductBloc>()..add(LoadProducts())),
        BlocProvider<AttributeDefinitionBloc>(
            create: (context) => di.sl<AttributeDefinitionBloc>()
              ..add(const LoadDefinitions())),
        BlocProvider<ShopBloc>(
            create: (context) => di.sl<ShopBloc>()..add(LoadShopEvent())),
        BlocProvider<BillingBloc>(
            create: (context) => di.sl<BillingBloc>()
              ..add(const LoadExchangeRateEvent())
              ..add(const LoadInventorySettingsEvent())
              ..add(const LoadPrintSettingsEvent())),
        BlocProvider<PrinterBloc>(
            create: (context) =>
                di.sl<PrinterBloc>()..add(InitPrinterEvent())),
        BlocProvider<HistoryBloc>(
            create: (context) =>
                di.sl<HistoryBloc>()..add(LoadHistoryEvent())),
        BlocProvider<CustomerBloc>(
            create: (context) =>
                di.sl<CustomerBloc>()..add(LoadCustomers())),
        BlocProvider<CashboxBloc>(
            create: (context) =>
                di.sl<CashboxBloc>()..add(const LoadCashbox())),
      ],
      child: const _ThemedApp(),
    );
  }
}

/// Rebuilds `MaterialApp.router` when the theme preference changes.
///
/// `AnimatedBuilder` is just the listener plumbing here (no animation) — it's
/// the standard way to rebuild on a `ChangeNotifier` without pulling in a
/// state-management package the app doesn't otherwise use.
class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    final themeController = di.sl<ThemeController>();
    final fontScaleController = di.sl<FontScaleController>();
    return AnimatedBuilder(
      animation: Listenable.merge([themeController, fontScaleController]),
      builder: (context, _) => MaterialApp.router(
        title: 'فواتير',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.mode,
        scaffoldMessengerKey: rootMessengerKey,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // Wraps every route: prompts once if the remote config advertises a
        // newer app version. Lives here (not on a page) so it fires regardless
        // of the licensing gate's current screen. Also applies the app-wide
        // font-size preference (Plan 011 #1) by overriding textScaler for the
        // whole tree.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(fontScaleController.factor)),
          child: _UpdateChecker(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
