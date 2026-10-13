import 'package:flutter/material.dart';
import 'package:watad/features/navigation/shared/presentation/widgets/navigation_shell.dart';
import 'package:watad/features/navigation/shared/presentation/widgets/navigation_tab.dart';

/// The contractor's main screen: their tabs and the bottom navigation.
class ContractorNavigationPage extends StatelessWidget {
  const ContractorNavigationPage({
    required this.screens,
    this.selectedRouteName,
    super.key,
  });

  /// The contractor's tabs, in order; in Arabic the first one is on the
  /// right. How a feature becomes a tab: see `ClientNavigationPage.tabs`.
  static const List<NavigationTab> tabs = [
    NavigationTab(
      labelKey: 'navigation.dashboard',
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard_rounded,
    ),
    NavigationTab(
      labelKey: 'navigation.work',
      icon: Icons.work_outline_rounded,
      selectedIcon: Icons.work_rounded,
    ),
    NavigationTab(
      labelKey: 'navigation.market',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront_rounded,
    ),
    NavigationTab(
      labelKey: 'navigation.chats',
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
    ),
    NavigationTab(
      labelKey: 'navigation.my_business',
      icon: Icons.business_outlined,
      selectedIcon: Icons.business_rounded,
    ),
  ];

  /// Builds each tab's screen; the route takes them from getIt.
  final List<Widget Function()?> screens;

  /// The tab to open, from the route's `tab` parameter.
  final String? selectedRouteName;

  @override
  Widget build(BuildContext context) => NavigationShell(
    tabs: tabs,
    screens: screens,
    selectedRouteName: selectedRouteName,
  );
}
