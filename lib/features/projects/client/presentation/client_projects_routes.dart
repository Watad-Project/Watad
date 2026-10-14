import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_offers_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';
import 'package:watad/features/projects/client/presentation/pages/client_project_offers_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_projects_page.dart';

final List<RouteBase> clientProjectsRoutes = [
  GoRoute(
    name: ClientProjectsRoutes.projectsName,
    path: ClientProjectsRoutes.projectsPath,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<ClientProjectsBloc>()..add(const ClientProjectsFetched()),
      child: const ClientProjectsPage(),
    ),
  ),
  GoRoute(
    name: ClientProjectsRoutes.projectOffersName,
    path: ClientProjectsRoutes.projectOffersPath,
    builder: (context, state) {
      final projectId = state.pathParameters['id']!;
      return BlocProvider(
        create: (_) =>
            getIt<ClientProjectOffersBloc>()
              ..add(ClientProjectOffersFetched(projectId)),
        child: ClientProjectOffersPage(projectId: projectId),
      );
    },
  ),
];
