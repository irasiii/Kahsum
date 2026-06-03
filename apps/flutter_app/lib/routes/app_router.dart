import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/language_picker_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/deals/screens/home_screen.dart';
import '../features/deals/screens/nearby_map_screen.dart';
import '../features/deals/screens/deal_detail_screen.dart';
import '../features/trader/screens/my_deals_screen.dart';
import '../features/trader/screens/create_deal_screen.dart';
import '../features/trader/screens/edit_deal_screen.dart';
import '../features/trader/screens/qr_scanner_screen.dart';
import '../features/consumer/screens/my_claims_screen.dart';
import '../features/consumer/screens/qr_display_screen.dart';
import '../features/consumer/screens/rate_deal_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/main_shell.dart';
import '../providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // ── Onboarding ─────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        name: 'languagePicker',
        builder: (_, __) => const LanguagePickerScreen(),
      ),

      // ── Auth ───────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),

      // ── Main shell with 4-tab bottom nav ───────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Branch 0 — Browse (everyone)
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (_, __) => const HomeScreen(),
            ),
          ]),

          // Branch 1 — consumer: Nearby Map | trader: My Deals
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/tab2',
              builder: (_, __) => Consumer(
                builder: (ctx, ref, _) {
                  final auth = ref.watch(authProvider);
                  return auth.userType == 'trader'
                      ? const MyDealsScreen()
                      : const NearbyMapScreen();
                },
              ),
            ),
          ]),

          // Branch 2 — consumer: My Claims | trader: Create Deal
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/tab3',
              builder: (_, __) => Consumer(
                builder: (ctx, ref, _) {
                  final auth = ref.watch(authProvider);
                  return auth.userType == 'trader'
                      ? const CreateDealScreen()
                      : const MyClaimsScreen();
                },
              ),
            ),
          ]),

          // Branch 3 — Profile (everyone)
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ]),
        ],
      ),

      // ── Full-screen overlays (no bottom nav) ───────────────────────────

      GoRoute(
        path: '/deal/:id',
        name: 'dealDetail',
        builder: (_, state) =>
            DealDetailScreen(dealId: state.pathParameters['id']!),
      ),

      GoRoute(
        path: '/deal/edit/:id',
        name: 'editDeal',
        builder: (_, state) =>
            EditDealScreen(dealId: state.pathParameters['id']!),
      ),

      GoRoute(
        path: '/qr/:claimId',
        name: 'qrDisplay',
        builder: (_, state) =>
            QrDisplayScreen(claimId: state.pathParameters['claimId']!),
      ),

      GoRoute(
        path: '/rate/:claimId',
        name: 'rateDeal',
        builder: (_, state) =>
            RateDealScreen(claimId: state.pathParameters['claimId']!),
      ),

      GoRoute(
        path: '/scan',
        name: 'scanQr',
        builder: (_, __) => const QrScannerScreen(),
      ),

      GoRoute(
        path: '/create',
        name: 'createDeal',
        builder: (_, __) => const CreateDealScreen(),
      ),
    ],
  );
});
