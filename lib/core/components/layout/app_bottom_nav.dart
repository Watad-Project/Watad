import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';

/// One tab of an [AppBottomNav].
class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
  });

  final IconData icon;
  final String label;

  /// Shown when the tab is selected, e.g. the filled form of [icon].
  final IconData? activeIcon;
}

/// The bar of main tabs at the bottom of the main screens. One component for
/// every role: the shell passes the tabs of the signed-in role (client:
/// Home, My projects, Market, Chats, Account; contractor: Dashboard, Work,
/// Market, Chats, My business).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: [
          for (final item in items)
            BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: Icon(item.activeIcon ?? item.icon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}
