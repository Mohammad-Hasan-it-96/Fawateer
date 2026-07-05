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
import '../../features/product/domain/entities/product.dart';
import '../../features/product/presentation/pages/add_product_page.dart';
import '../../features/product/presentation/pages/edit_product_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shop/presentation/pages/shop_details_page.dart';
import 'app_shell.dart';

/// The single shared LicenseBloc instance the gate reacts to.
final _licenseBloc = sl<LicenseBloc>();

/// Locations that stay reachable while unlicensed (the activation flow itself,
/// plus the splash shown during the initial check).
bool _isGateRoute(String location) =>
    location == '/splash' || location.startsWith('/activation');

final router = GoRouter(
  initialLocation: '/pos',
  // Re-run [redirect] whenever the license state changes.
  refreshListenable: _LicenseGateListenable(_licenseBloc.stream),
  redirect: (context, state) {
    final license = _licenseBloc.state;
    final loc = state.matchedLocation;

    // Still verifying at startup → hold on the splash.
    if (license.isResolving) {
      return _isGateRoute(loc) ? null : '/splash';
    }
    // No valid subscription → funnel to activation (but let the flow's own
    // screens through).
    if (!license.isActive) {
      return _isGateRoute(loc) ? null : '/activation';
    }
    // Active: don't let the user sit on the gate screens.
    if (loc == '/splash' || loc == '/activation') return '/pos';
    return null;
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

        // ── Branch 3: Settings ─────────────────────────────────────────
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
                GoRoute(
                  path: 'customers',
                  builder: (context, state) => const CustomersPage(),
                  routes: [
                    GoRoute(
                      path: 'add',
                      builder: (context, state) => const AddEditCustomerPage(),
                    ),
                    GoRoute(
                      path: 'edit/:id',
                      builder: (context, state) => AddEditCustomerPage(
                          customer: state.extra as Customer?),
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
