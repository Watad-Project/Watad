import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_post_project_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_deed_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_offers_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';
import 'package:watad/features/projects/client/presentation/pages/client_post_project_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_project_deed_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_project_offers_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_projects_page.dart';

final List<RouteBase> clientProjectsRoutes = [
  GoRoute(
    name: ClientProjectsRoutes.postProjectName,
    path: ClientProjectsRoutes.postProjectPath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<ClientPostProjectBloc>(),
      child: const ClientPostProjectPage(),
    ),
  ),
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
      final projectId = state.pathParameters['projectId']!;
      return BlocProvider(
        create: (_) =>
            getIt<ClientProjectOffersBloc>()
              ..add(ClientProjectOffersFetched(projectId)),
        child: ClientProjectOffersPage(projectId: projectId),
      );
    },
  ),
  GoRoute(
    name: ClientProjectsRoutes.projectDeedName,
    path: ClientProjectsRoutes.projectDeedPath,
    builder: (context, state) {
      final projectId = state.pathParameters['projectId']!;
      return BlocProvider(
        create: (_) =>
            getIt<ClientProjectDeedBloc>()
              ..add(ClientProjectDeedFetched(projectId)),
        child: ClientProjectDeedPage(projectId: projectId),
      );
    },
  ),
];
