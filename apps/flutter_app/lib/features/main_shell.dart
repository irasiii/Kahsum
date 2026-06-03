import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

/// Bottom-nav shell — 4 branches, content adapts per user type.
///
/// Branch layout (fixed in router):
///   0  → Browse (/home)         — everyone
///   1  → Tab2                   — consumer: Nearby | trader: My Deals
///   2  → Tab3                   — consumer: My Claims | trader: Create Deal
///   3  → Profile (/profile)     — everyone
class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isTrader = auth.userType == 'trader';

    final items = isTrader
        ? <_NavItem>[
            _NavItem(
              icon: Icons.storefront_outlined,
              activeIcon: Icons.storefront,
              label: 'dealsBrowse'.tr(),
            ),
            _NavItem(
              icon: Icons.list_alt_outlined,
              activeIcon: Icons.list_alt,
              label: 'traderMyDeals'.tr(),
            ),
            _NavItem(
              icon: Icons.add_circle_outline,
              activeIcon: Icons.add_circle,
              label: 'traderCreateDeal'.tr(),
            ),
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'settingsTitle'.tr(),
            ),
          ]
        : <_NavItem>[
            _NavItem(
              icon: Icons.storefront_outlined,
              activeIcon: Icons.storefront,
              label: 'dealsBrowse'.tr(),
            ),
            _NavItem(
              icon: Icons.map_outlined,
              activeIcon: Icons.map,
              label: 'dealsNearby'.tr(),
            ),
            _NavItem(
              icon: Icons.confirmation_num_outlined,
              activeIcon: Icons.confirmation_num,
              label: 'consumerMyDeals'.tr(),
            ),
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'settingsTitle'.tr(),
            ),
          ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        items: items
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.activeIcon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(
      {required this.icon,
      required this.activeIcon,
      required this.label});
}
