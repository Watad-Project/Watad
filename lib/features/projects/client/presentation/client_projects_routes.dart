import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_post_project_bloc.dart';
import 'package:watad/features/projects/client/presentation/pages/client_post_project_page.dart';

final List<RouteBase> clientProjectsRoutes = [
  GoRoute(
    name: ClientProjectsRoutes.postProjectName,
    path: ClientProjectsRoutes.postProjectPath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<ClientPostProjectBloc>(),
      child: const ClientPostProjectPage(),
    ),
  ),
];
