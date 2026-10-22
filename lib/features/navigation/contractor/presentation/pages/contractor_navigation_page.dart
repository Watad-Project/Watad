import 'package:flutter/material.dart';
import 'package:watad/core/router/routes/contractor_dashboard_routes.dart';
import 'package:watad/core/router/routes/contractor_work_routes.dart';
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
      labelKey: 'dashboard.tab_title',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      routeName: ContractorDashboardRoutes.dashboardName,
    ),
    NavigationTab(
      labelKey: 'work.tab_title',
      icon: Icons.work_outline,
      selectedIcon: Icons.work,
      routeName: ContractorWorkRoutes.workName,
    ),
    NavigationTab.placeholder(),
    NavigationTab.placeholder(),
    NavigationTab.placeholder(),
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
