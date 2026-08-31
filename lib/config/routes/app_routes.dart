import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/service_locator.dart';
import '../../features/billing/domain/entities/invoice_list_item.dart';
import '../../features/billing/presentation/pages/checkout_page.dart';
import '../../features/billing/presentation/pages/history_page.dart';
import '../../features/billing/presentation/pages/invoice_detail_page.dart';
import '../../features/billing/presentation/pages/home_page.dart';
import '../../features/billing/presentation/pages/scanner_page.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/ledger/domain/entities/customer.dart';
import '../../features/ledger/presentation/bloc/ledger_bloc.dart';
import '../../features/ledger/presentation/pages/add_edit_customer_page.dart';
import '../../features/ledger/presentation/pages/customer_detail_page.dart';
import '../../features/ledger/presentation/pages/customers_page.dart';
import '../../features/licensing/presentation/bloc/license_bloc.dart';
import '../../features/licensing/presentation/pages/activation_page.dart';
import '../../features/licensing/presentation/pages/splash_page.dart';
import '../../features/licensing/presentation/pages/subscription_plans_page.dart';
import '../../features/licensing/presentation/pages/subscription_status_page.dart';
import '../../features/licensing/presentation/pages/verification_required_page.dart';
import '../../features/licensing/presentation/pages/welcome_page.dart';
import '../../features/sync/presentation/pages/join_shop_page.dart';
import '../../features/product/domain/entities/product.dart';
import '../../features/product/domain/product_stock_filter.dart';
import '../../features/product/presentation/pages/add_product_page.dart';
import '../../features/product/presentation/pages/edit_product_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/product/presentation/pages/product_units_page.dart';
import '../../features/product/presentation/bloc/product_unit_bloc.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shop/presentation/pages/shop_details_page.dart';
import '../../features/attributes/presentation/pages/attribute_fields_page.dart';
import '../../features/cashbox/presentation/pages/cashbox_page.dart';
import '../../features/cashbox/presentation/pages/cashbox_history_page.dart';
import '../../features/backup/presentation/bloc/backup_bloc.dart';
import '../../features/backup/presentation/pages/backup_page.dart';
import '../../features/sync/presentation/bloc/sync_bloc.dart';
import '../../features/sync/presentation/pages/sync_page.dart';
import 'app_shell.dart';

/// The single shared LicenseBloc instance the gate reacts to.
final _licenseBloc = sl<LicenseBloc>();

/// Root navigator key. Exists for code that lives *above* the router's
/// Navigator — the update checker wraps `MaterialApp.router` via `builder:`,
/// so its own context has no Navigator ancestor and `showDialog` from it
/// throws (silently, inside a post-frame future). Dialogs opened from up
/// there must use `rootNavigatorKey.currentContext` instead.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// The activation-flow screens (reachable while unlicensed).
/// The first-run fork: new shop, or another phone for an existing one.
/// Reached only by a device that has never registered — once it has, the
/// question is already answered.
const _welcome = '/welcome';
const _activationForm = '/activation'; // name/phone → create_device
const _activationPlans = '/activation/plans'; // pick a plan → contact support
const _activationVerify = '/activation/verify'; // offline/tamper → reconnect

/// The licence gate's decision, as a pure function of the licence state and
/// where the user currently is.
///
/// Lifted out of the `GoRouter` closure so it can be tested. This is the app's
/// front door — it decides, on every navigation and on every licence state
/// change, whether a shopkeeper can reach their till at all — and until now the
/// only way to exercise it was to run the app. A wrong branch here does not
/// throw; it silently strands someone on a screen, which is exactly the failure
/// the first-run fork introduced a new way to hit.
///
/// Returns null to stay put, or the location to go to.
String? licenseGateRedirect(LicenseState license, String loc) {

    // 1. Before the first check resolves → hold on the splash.
    if (!license.bootstrapped) {
      return loc == '/splash' ? null : '/splash';
    }

    // 2. Active subscription → into the app; never sit on a gate screen.
    if (license.isActive) {
      if (loc == '/splash' ||
          loc.startsWith('/activation') ||
          loc.startsWith(_welcome)) {
        return '/pos';
      }
      return null;
    }

    // 3. Blocked by a guard, not by the subscription itself: still verified and
    //    not expired, but too long offline or the clock was rolled back. This
    //    is fixed by reconnecting (a successful check clears both), so send the
    //    user to the "reconnect to verify" screen — NOT the plans page, which
    //    would read as a payment demand for something they already paid.
    final lic = license.license;
    if (lic.isVerified &&
        !lic.isExpired &&
        (lic.offlineLimitExceeded || lic.timeTampered)) {
      return loc == _activationVerify ? null : _activationVerify;
    }

    // 4. No valid subscription. Pick the right gate screen:
    //    - not yet registered (no name/phone) → the activation form, which
    //      collects the details and calls `create_device`.
    //    - registered but unverified → the plan catalogue, where the user picks
    //      a plan and contacts support (WhatsApp / email / Telegram).
    // The first-run fork owns the whole flow while the user is inside it —
    // including the moment a join succeeds, when the licence state has not
    // caught up yet and the bare `registered` check below would yank the
    // shopkeeper onto the registration form mid-restore.
    if (loc.startsWith(_welcome)) return null;

    // A phone that JOINED a shop is neither of the two cases below. It has no
    // name of its own (the owner's subscription covers it, ADR 0011 Decision
    // 2), so `registered` is false and it would be offered "create a new shop"
    // — the one thing it must never do, because taking that door makes a second
    // business out of a till that already belongs to one. It must not be shown
    // the plans page either: renewing is the owner's job on the main phone, and
    // asking a member to buy is asking a shop to pay twice.
    //
    // The verify screen is the honest place: reachable, retryable, and true
    // whether the cause is no network on the first launch after joining, a
    // revoked seat, or the owner's subscription lapsing. A revoke clears the
    // seat credential (`SyncScheduler._onRevoked`), so a genuinely unlinked
    // phone falls through to the normal path on its next check.
    if (license.isLinkedMember) {
      return loc == _activationVerify ? null : _activationVerify;
    }

    // A device that has never registered is asked the fork question first. It
    // is not the activation form's job to guess: for the shop's second phone
    // the form asks for a name and a number that the owner has already given
    // once, and then drops them into an empty shop they have to go and link by
    // hand from Settings.
    final target = license.registered ? _activationPlans : _welcome;

    // Let the activation flow's own screens stay put, but move a registered user
    // off the bare name form onto plan selection (unless a request is in flight,
    // so the form's busy overlay isn't yanked away mid-activation). A user
    // sitting on the verify screen whose block turned into a real
    // expiry/unverified state falls through to [target] above it.
    if (loc == _activationForm || loc == _activationPlans) {
      if (license.registered && loc == _activationForm && !license.isBusy) {
        return _activationPlans;
      }
      return null;
    }
    return target;
}

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/pos',
  // Re-run [redirect] whenever the license state changes.
  refreshListenable: _LicenseGateListenable(_licenseBloc.stream),
  redirect: (context, state) =>
      licenseGateRedirect(_licenseBloc.state, state.matchedLocation),
  routes: [
    // Licensing gate (top-level, outside the tab shell).
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: _welcome,
      builder: (context, state) => const WelcomePage(),
      routes: [
        GoRoute(
          path: 'join',
          // Scopes its own SyncBloc, exactly as `/settings/sync` does — the
          // enrollment state belongs to this screen and nothing outside it
          // should pay for a listener.
          builder: (context, state) => BlocProvider(
            create: (_) => sl<SyncBloc>(),
            child: const JoinShopPage(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/activation',
      builder: (context, state) => const ActivationPage(),
      routes: [
        GoRoute(
          path: 'plans',
          builder: (context, state) => const SubscriptionPlansPage(),
        ),
        GoRoute(
          path: 'verify',
          builder: (context, state) => const VerificationRequiredPage(),
        ),
      ],
    ),

    // Scanner is a top-level modal route so it can be pushed from any branch
    GoRoute(
      path: '/scanner',
      builder: (context, state) => const ScannerPage(),
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) =>
          AppShell(navigationShell: shell),
      branches: [
        // ── Branch 0: POS ──────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pos',
              builder: (context, state) => const HomePage(),
              routes: [
                GoRoute(
                  path: 'checkout',
                  builder: (context, state) => const CheckoutPage(),
                ),
              ],
            ),
          ],
        ),

        // ── Branch 1: Reports (analytics dashboard + sales audit) ──────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              // DashboardBloc is scoped here (like LedgerBloc/BackupBloc): it
              // lives as long as this branch is kept alive by the indexed stack,
              // reloading off its own change ticker.
              builder: (context, state) => BlocProvider(
                create: (_) => sl<DashboardBloc>()..add(const LoadDashboard()),
                child: const HistoryPage(),
              ),
              routes: [
                GoRoute(
                  path: 'detail/:id',
                  builder: (context, state) {
                    final invoice = state.extra as InvoiceListItem?;
                    if (invoice == null) return const HistoryPage();
                    return InvoiceDetailPage(invoice: invoice);
                  },
                ),
              ],
            ),
          ],
        ),

        // ── Branch 2: Products ─────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/products',
              // `extra` optionally carries a stock filter, so the Reports
              // low-stock card can hand off with it already applied
              // (Plan 013 #1).
              builder: (context, state) => ProductListPage(
                  initialStockFilter: state.extra is ProductStockFilter
                      ? state.extra as ProductStockFilter
                      : null),
              routes: [
                GoRoute(
                  path: 'add',
                  // `extra` carries either a barcode (the POS sends the user
                  // here after scanning one that isn't registered yet) or the
                  // product this one is a second price for (Plan 015 Case A).
                  // Two types on one `extra` rather than two routes: it is the
                  // same page and the same form, differing only in what it
                  // starts from.
                  builder: (context, state) => AddProductPage(
                    initialBarcode: state.extra is String
                        ? state.extra as String
                        : null,
                    variantOf:
                        state.extra is Product ? state.extra as Product : null,
                  ),
                ),
                GoRoute(
                  path: 'edit/:id',
                  builder: (context, state) {
                    final product = state.extra as Product?;
                    if (product == null) return const ProductListPage();
                    return EditProductPage(product: product);
                  },
                ),
                GoRoute(
                  path: 'units/:id',
                  builder: (context, state) {
                    final product = state.extra as Product?;
                    if (product == null) return const ProductListPage();
                    // ProductUnitBloc is per-SKU, so scope it to this route —
                    // same precedent as LedgerBloc on the customer detail page.
                    return BlocProvider(
                      create: (_) =>
                          sl<ProductUnitBloc>()..add(LoadUnits(product.id)),
                      child: ProductUnitsPage(product: product),
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        // ── Branch 3: Customers & Debts ────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/customers',
              builder: (context, state) => const CustomersPage(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) => const AddEditCustomerPage(),
                ),
                GoRoute(
                  path: 'edit/:id',
                  builder: (context, state) =>
                      AddEditCustomerPage(customer: state.extra as Customer?),
                ),
                GoRoute(
                  path: 'detail/:id',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    // LedgerBloc is per-customer, so scope it to this route.
                    return BlocProvider(
                      create: (_) => sl<LedgerBloc>()..add(LoadLedger(id)),
                      child: CustomerDetailPage(customerId: id),
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        // ── Branch 4: Settings ─────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
              routes: [
                GoRoute(
                  path: 'shop',
                  builder: (context, state) => const ShopDetailsPage(),
                ),
                // Product fields (Plan 010). AttributeDefinitionBloc is app-wide
                // (provided in main.dart), so no scoped provider is needed.
                GoRoute(
                  path: 'product-fields',
                  builder: (context, state) => const AttributeFieldsPage(),
                ),
                // Cashbox (cash ledger). The CashboxBloc is app-wide (provided
                // in main.dart), so these routes need no scoped BlocProvider.
                GoRoute(
                  path: 'cashbox',
                  builder: (context, state) => const CashboxPage(),
                  routes: [
                    GoRoute(
                      path: 'history',
                      builder: (context, state) => const CashboxHistoryPage(),
                    ),
                  ],
                ),
                // Backup & Restore (Google Drive). BackupBloc is scoped to this
                // route (like LedgerBloc) — only needed while this page is open.
                GoRoute(
                  path: 'backup',
                  builder: (context, state) => BlocProvider(
                    create: (_) => sl<BackupBloc>(),
                    child: const BackupPage(),
                  ),
                ),
                // Devices & sync (Plan 002). SyncBloc is scoped here, like
                // BackupBloc — nothing outside this page needs enrollment
                // state. The route dispatches nothing; SyncPage.initState
                // fires LoadSyncStatus.
                GoRoute(
                  path: 'sync',
                  builder: (context, state) => BlocProvider(
                    create: (_) => sl<SyncBloc>(),
                    child: const SyncPage(),
                  ),
                ),
                // Subscription management (reachable only while active; the gate
                // funnels unlicensed users to /activation instead).
                GoRoute(
                  path: 'subscription',
                  builder: (context, state) => const SubscriptionStatusPage(),
                  routes: [
                    GoRoute(
                      path: 'plans',
                      builder: (context, state) =>
                          const SubscriptionPlansPage(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Bridges the [LicenseBloc] stream to a [Listenable] so GoRouter re-evaluates
/// [GoRouter.redirect] on every license state change (e.g. check completes,
/// activation succeeds).
class _LicenseGateListenable extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;
  _LicenseGateListenable(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
