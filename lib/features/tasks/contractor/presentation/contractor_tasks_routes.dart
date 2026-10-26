import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/contractor_tasks_routes.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_project_tasks_bloc.dart';
import 'package:watad/features/tasks/contractor/presentation/pages/contractor_project_tasks_page.dart';

/// GoRouter entries owned by lib/features/tasks/contractor/.
///
/// Spread into the single router in lib/core/router/app_router.dart.
final List<RouteBase> contractorTasksRoutes = <RouteBase>[
  GoRoute(
    path: ContractorTasksRoutes.projectTasksPath,
    name: ContractorTasksRoutes.projectTasksName,
    builder: (context, state) {
      final projectId = state.pathParameters['projectId']!;
      return BlocProvider(
        create: (_) =>
            getIt<ContractorProjectTasksBloc>()
              ..add(ContractorProjectTasksFetched(projectId)),
        child: ContractorProjectTasksPage(projectId: projectId),
      );
    },
  ),
];
