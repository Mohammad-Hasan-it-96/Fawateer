import 'package:go_router/go_router.dart';

import '../../features/billing/presentation/pages/checkout_page.dart';
import '../../features/billing/presentation/pages/history_page.dart';
import '../../features/billing/presentation/pages/home_page.dart';
import '../../features/billing/presentation/pages/scanner_page.dart';
import '../../features/product/domain/entities/product.dart';
import '../../features/product/presentation/pages/add_product_page.dart';
import '../../features/product/presentation/pages/edit_product_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shop/presentation/pages/shop_details_page.dart';
import 'app_shell.dart';

final router = GoRouter(
  initialLocation: '/pos',
  routes: [
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
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
