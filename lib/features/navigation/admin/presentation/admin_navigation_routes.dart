import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/admin_navigation_routes.dart';
import 'package:watad/features/navigation/admin/presentation/pages/admin_navigation_page.dart';

final List<RouteBase> adminNavigationRoutes = [
  GoRoute(
    name: AdminNavigationRoutes.navigationName,
    path: AdminNavigationRoutes.navigationPath,
    builder: (context, state) => AdminNavigationPage(
      // Each tab's feature registered its first page in getIt under the
      // tab's route name, in its injection file.
      screens: [
        for (final tab in AdminNavigationPage.tabs)
          if (tab.routeName case final name?)
            () => getIt<Widget>(instanceName: name)
          else
            null,
      ],
      selectedRouteName: state.uri.queryParameters['tab'],
    ),
  ),
];
