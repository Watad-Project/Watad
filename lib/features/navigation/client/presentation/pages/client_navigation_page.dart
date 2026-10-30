import 'package:flutter/material.dart';
import 'package:watad/core/router/routes/client_home_routes.dart';
import 'package:watad/core/router/routes/client_profile_routes.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
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
  ///
  /// How a feature becomes a tab (the same for every role):
  /// 1. Build the page as usual, with its own `GoRoute` and names file, and
  ///    without a bottom bar: the navigation adds it.
  /// 2. In the feature's injection file, register the page under its route
  ///    name. A page with a bloc is registered through a small tab widget in
  ///    `presentation/widgets/` that receives the bloc, provides it with
  ///    `BlocProvider.value` and closes it in `dispose`:
  ///    ```dart
  ///    getIt.registerFactory<Widget>(
  ///      () => const ClientProjectsPage(),
  ///      instanceName: ClientProjectsRoutes.projectsName,
  ///    );
  ///    ```
  /// 3. Replace one placeholder below with the feature's tab:
  ///    `NavigationTab(labelKey: …, icon: …, selectedIcon: …, routeName: …)`,
  ///    with that route name. Add the label's key to every language file,
  ///    and the feature's `register…Dependencies(getIt)` to the setUp of this
  ///    folder's routes test.
  static const List<NavigationTab> tabs = [
    NavigationTab(
      labelKey: 'home.tab',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      routeName: ClientHomeRoutes.homeName,
    ),
    NavigationTab(
      labelKey: 'projects.client.tab',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment_rounded,
      routeName: ClientProjectsRoutes.projectsName,
    ),
    NavigationTab.placeholder(),
    NavigationTab.placeholder(),
    NavigationTab(
      labelKey: 'profile.client.tab',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      routeName: ClientProfileRoutes.profileName,
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
