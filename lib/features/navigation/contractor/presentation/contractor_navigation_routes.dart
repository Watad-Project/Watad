import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/contractor_navigation_routes.dart';
import 'package:watad/features/navigation/contractor/presentation/pages/contractor_navigation_page.dart';

final List<RouteBase> contractorNavigationRoutes = [
  GoRoute(
    name: ContractorNavigationRoutes.navigationName,
    path: ContractorNavigationRoutes.navigationPath,
    builder: (context, state) => ContractorNavigationPage(
      // Each tab's feature registered its first page in getIt under the
      // tab's route name, in its injection file.
      screens: [
        for (final tab in ContractorNavigationPage.tabs)
          if (tab.routeName case final name?)
            () => getIt<Widget>(instanceName: name)
          else
            null,
      ],
      selectedRouteName: state.uri.queryParameters['tab'],
      // A tab's feature may also register its badge's live count under the
      // tab's route name.
      badges: [
        for (final tab in ContractorNavigationPage.tabs)
          if (tab.routeName case final name?
              when getIt.isRegistered<Stream<int>>(instanceName: name))
            () => getIt<Stream<int>>(instanceName: name)
          else
            null,
      ],
    ),
  ),
];
