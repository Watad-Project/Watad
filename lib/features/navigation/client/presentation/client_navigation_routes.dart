import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/client_navigation_routes.dart';
import 'package:watad/features/navigation/client/presentation/pages/client_navigation_page.dart';

final List<RouteBase> clientNavigationRoutes = [
  GoRoute(
    name: ClientNavigationRoutes.navigationName,
    path: ClientNavigationRoutes.navigationPath,
    builder: (context, state) => ClientNavigationPage(
      // Each tab's feature registered its first page in getIt under the
      // tab's route name, in its injection file.
      screens: [
        for (final tab in ClientNavigationPage.tabs)
          if (tab.routeName case final name?)
            () => getIt<Widget>(instanceName: name)
          else
            null,
      ],
      selectedRouteName: state.uri.queryParameters['tab'],
    ),
  ),
];
