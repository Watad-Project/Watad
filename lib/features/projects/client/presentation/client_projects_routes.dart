import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_post_project_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_deed_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_offers_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_tasks_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_task_details_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_task_update_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_task_update_reject_bloc.dart';
import 'package:watad/features/projects/client/presentation/pages/client_post_project_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_project_deed_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_project_offers_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_project_tasks_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_projects_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_task_details_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_task_update_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_task_update_reject_page.dart';

final List<RouteBase> clientProjectsRoutes = [
  // Before the project's tasks: '/client/projects/:projectId' would also
  // match '/client/projects/post-project'.
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
    name: ClientProjectsRoutes.projectTasksName,
    path: ClientProjectsRoutes.projectTasksPath,
    builder: (context, state) {
      final projectId = state.pathParameters['projectId']!;
      return BlocProvider(
        create: (_) =>
            getIt<ClientProjectTasksBloc>()
              ..add(ClientProjectTasksFetched(projectId)),
        child: ClientProjectTasksPage(projectId: projectId),
      );
    },
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
  GoRoute(
    name: ClientProjectsRoutes.taskDetailsName,
    path: ClientProjectsRoutes.taskDetailsPath,
    builder: (context, state) {
      final projectId = state.pathParameters['projectId']!;
      final taskId = state.pathParameters['taskId']!;
      return BlocProvider(
        create: (_) => getIt<ClientTaskDetailsBloc>()
          ..add(ClientTaskDetailsFetched(projectId: projectId, taskId: taskId)),
        child: ClientTaskDetailsPage(projectId: projectId, taskId: taskId),
      );
    },
  ),
  GoRoute(
    name: ClientProjectsRoutes.taskUpdateName,
    path: ClientProjectsRoutes.taskUpdatePath,
    builder: (context, state) {
      final projectId = state.pathParameters['projectId']!;
      final updateId = state.pathParameters['updateId']!;
      return BlocProvider(
        create: (_) =>
            getIt<ClientTaskUpdateBloc>()
              ..add(ClientTaskUpdateFetched(updateId)),
        child: ClientTaskUpdatePage(projectId: projectId, updateId: updateId),
      );
    },
  ),
  GoRoute(
    name: ClientProjectsRoutes.taskUpdateRejectName,
    path: ClientProjectsRoutes.taskUpdateRejectPath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<ClientTaskUpdateRejectBloc>(),
      child: ClientTaskUpdateRejectPage(
        projectId: state.pathParameters['projectId']!,
        updateId: state.pathParameters['updateId']!,
      ),
    ),
  ),
];
