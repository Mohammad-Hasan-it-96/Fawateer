import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';
import 'config/routes/app_routes.dart';
import 'core/config/remote_config_service.dart';
import 'core/service_locator.dart' as di;
import 'core/theme/app_theme.dart';
import 'features/billing/presentation/bloc/billing_bloc.dart';
import 'features/billing/presentation/bloc/history_bloc.dart';
import 'features/product/presentation/bloc/product_bloc.dart';
import 'features/shop/presentation/bloc/shop_bloc.dart';
import 'features/settings/presentation/bloc/printer_bloc.dart';
import 'features/settings/presentation/bloc/printer_event.dart';
import 'features/licensing/presentation/bloc/license_bloc.dart';
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

  runApp(const MyApp());

  // Start FCM live-unlock (fire-and-forget; self-disables without Firebase
  // config). A license-related push re-checks the subscription on the shared
  // LicenseBloc, so the router gate unlocks the app the instant the operator
  // activates the device — no restart needed. If it arrives while the app is
  // open, also show a visible banner (background/terminated get a tray notice).
  di.sl<PushNotificationService>().initialize(
        onLicenseChanged: () => di.sl<LicenseBloc>().add(CheckLicenseEvent()),
        onForegroundLicenseChange: _showSubscriptionActivatedBanner,
      );
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

class _UpdateCheckerState extends State<_UpdateChecker> {
  bool _prompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());
  }

  Future<void> _maybePrompt() async {
    final service = di.sl<RemoteConfigService>();
    await service.ensureLoaded();
    if (!mounted || _prompted) return;
    if (!service.updateAvailable) return;
    _prompted = true;

    final l10n = AppLocalizations.of(context);
    final notes = service.current?.updateNotes ?? const [];
    final url = service.downloadUrl;
    if (l10n == null) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.updateAvailableTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• $note'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.updateLater),
          ),
          FilledButton(
            onPressed: (url == null || url.isEmpty)
                ? null
                : () async {
                    Navigator.of(dialogContext).pop();
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  },
            child: Text(l10n.updateDownload),
          ),
        ],
      ),
    );
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
        BlocProvider<ShopBloc>(
            create: (context) => di.sl<ShopBloc>()..add(LoadShopEvent())),
        BlocProvider<BillingBloc>(
            create: (context) =>
                di.sl<BillingBloc>()..add(const LoadExchangeRateEvent())),
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
      child: MaterialApp.router(
        title: 'فواتير',
        theme: AppTheme.lightTheme,
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
        // of the licensing gate's current screen.
        builder: (context, child) =>
            _UpdateChecker(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
