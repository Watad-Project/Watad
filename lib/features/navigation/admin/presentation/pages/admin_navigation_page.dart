import 'package:flutter/widgets.dart';
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
  /// For now every tab is a placeholder. How a feature becomes a tab: see
  /// `ClientNavigationPage.tabs`.
  static const List<NavigationTab> tabs = [
    NavigationTab.placeholder(),
    NavigationTab.placeholder(),
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
