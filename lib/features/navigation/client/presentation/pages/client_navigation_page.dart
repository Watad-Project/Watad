import 'package:flutter/material.dart';
import 'package:watad/core/router/routes/client_home_routes.dart';
import 'package:watad/features/navigation/shared/presentation/widgets/navigation_shell.dart';
import 'package:watad/features/navigation/shared/presentation/widgets/navigation_tab.dart';

/// The client's main screen: their tabs and the bottom navigation.
class ClientNavigationPage extends StatelessWidget {
  const ClientNavigationPage({
    required this.screens,
    this.selectedRouteName,
    super.key,
  });

  /// The client's tabs, in order; in Arabic the first one is on the right.
  static const List<NavigationTab> tabs = [
    NavigationTab(
      labelKey: 'navigation.home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      routeName: ClientHomeRoutes.homeName,
    ),
    NavigationTab(
      labelKey: 'navigation.projects',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
    ),
    NavigationTab(
      labelKey: 'navigation.marketplace',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront,
    ),
    NavigationTab(
      labelKey: 'navigation.chats',
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
    ),
    NavigationTab(
      labelKey: 'navigation.account',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
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
