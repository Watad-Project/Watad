import 'package:flutter/material.dart';
import 'package:watad/core/router/routes/admin_dashboard_routes.dart';
import 'package:watad/core/router/routes/admin_reports_routes.dart';
import 'package:watad/core/router/routes/admin_review_routes.dart';
import 'package:watad/features/navigation/shared/presentation/widgets/navigation_shell.dart';
import 'package:watad/features/navigation/shared/presentation/widgets/navigation_tab.dart';

/// The admin's main screen: their tabs and the bottom navigation.
class AdminNavigationPage extends StatelessWidget {
  const AdminNavigationPage({
    required this.screens,
    this.selectedRouteName,
    super.key,
  });

  /// The admin's tabs, in order; in Arabic the first one is on the right.
  /// How a feature becomes a tab: see
  /// `ClientNavigationPage.tabs`.
  static const List<NavigationTab> tabs = [
    // First, so admins land here after signing in.
    NavigationTab(
      labelKey: 'dashboard.admin.tab',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      routeName: AdminDashboardRoutes.dashboardName,
    ),
    NavigationTab(
      labelKey: 'review.tab',
      icon: Icons.verified_user_outlined,
      selectedIcon: Icons.verified_user,
      routeName: AdminReviewRoutes.reviewName,
    ),
    NavigationTab(
      labelKey: 'reports.tab',
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag,
      routeName: AdminReportsRoutes.reportsName,
    ),
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
