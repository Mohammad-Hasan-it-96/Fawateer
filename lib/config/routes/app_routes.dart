import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/service_locator.dart';
import '../../features/billing/presentation/pages/checkout_page.dart';
import '../../features/billing/presentation/pages/history_page.dart';
import '../../features/billing/presentation/pages/home_page.dart';
import '../../features/billing/presentation/pages/scanner_page.dart';
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
import '../../features/product/domain/entities/product.dart';
import '../../features/product/presentation/pages/add_product_page.dart';
import '../../features/product/presentation/pages/edit_product_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shop/presentation/pages/shop_details_page.dart';
import '../../features/cashbox/presentation/pages/cashbox_page.dart';
import '../../features/cashbox/presentation/pages/cashbox_history_page.dart';
import 'app_shell.dart';

/// The single shared LicenseBloc instance the gate reacts to.
final _licenseBloc = sl<LicenseBloc>();

/// The activation-flow screens (reachable while unlicensed).
const _activationForm = '/activation'; // name/phone → create_device
const _activationPlans = '/activation/plans'; // pick a plan → contact support

final router = GoRouter(
  initialLocation: '/pos',
  // Re-run [redirect] whenever the license state changes.
  refreshListenable: _LicenseGateListenable(_licenseBloc.stream),
  redirect: (context, state) {
    final license = _licenseBloc.state;
    final loc = state.matchedLocation;

    // 1. Before the first check resolves → hold on the splash.
    if (!license.bootstrapped) {
      return loc == '/splash' ? null : '/splash';
    }

    // 2. Active subscription → into the app; never sit on a gate screen.
    if (license.isActive) {
      if (loc == '/splash' || loc.startsWith('/activation')) return '/pos';
      return null;
    }

    // 3. No valid subscription. Pick the right gate screen:
    //    - not yet registered (no name/phone) → the activation form, which
    //      collects the details and calls `create_device`.
    //    - registered but unverified → the plan catalogue, where the user picks
    //      a plan and contacts support (WhatsApp / email / Telegram).
    final target = license.registered ? _activationPlans : _activationForm;

    // Let the activation flow's own screens stay put, but move a registered user
    // off the bare name form onto plan selection (unless a request is in flight,
    // so the form's busy overlay isn't yanked away mid-activation).
    if (loc == _activationForm || loc == _activationPlans) {
      if (license.registered && loc == _activationForm && !license.isBusy) {
        return _activationPlans;
      }
      return null;
    }
    return target;
  },
  routes: [
    // Licensing gate (top-level, outside the tab shell).
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/activation',
      builder: (context, state) => const ActivationPage(),
      routes: [
        GoRoute(
          path: 'plans',
          builder: (context, state) => const SubscriptionPlansPage(),
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

        // ── Branch 1: History ──────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryPage(),
            ),
          ],
        ),

        // ── Branch 2: Products ─────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/products',
              builder: (context, state) => const ProductListPage(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) => const AddProductPage(),
                ),
                GoRoute(
                  path: 'edit/:id',
                  builder: (context, state) {
                    final product = state.extra as Product?;
                    if (product == null) return const ProductListPage();
                    return EditProductPage(product: product);
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
