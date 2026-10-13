import 'package:flutter/material.dart';
import 'package:watad/features/navigation/shared/presentation/widgets/navigation_shell.dart';
import 'package:watad/features/navigation/shared/presentation/widgets/navigation_tab.dart';

/// The admin's main screen: the admin sections as tabs and the bottom
/// navigation. They replace the section chips of the admin mockup.
class AdminNavigationPage extends StatelessWidget {
  const AdminNavigationPage({
    required this.screens,
    this.selectedRouteName,
    super.key,
  });

  /// The admin's tabs, in order; in Arabic the first one is on the right.
  /// How a feature becomes a tab: see `ClientNavigationPage.tabs`.
  static const List<NavigationTab> tabs = [
    NavigationTab(
      labelKey: 'navigation.verification',
      icon: Icons.verified_user_outlined,
      selectedIcon: Icons.verified_user_rounded,
    ),
    NavigationTab(
      labelKey: 'navigation.reports',
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag_rounded,
    ),
    NavigationTab(
      labelKey: 'navigation.listings',
      icon: Icons.sell_outlined,
      selectedIcon: Icons.sell_rounded,
    ),
    NavigationTab(
      labelKey: 'navigation.payments',
      icon: Icons.payments_outlined,
      selectedIcon: Icons.payments_rounded,
    ),
    NavigationTab(
      labelKey: 'navigation.users',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
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
