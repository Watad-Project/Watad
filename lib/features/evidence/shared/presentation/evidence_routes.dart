import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/evidence_routes.dart';
import 'package:watad/features/evidence/shared/presentation/bloc/evidence_export_bloc.dart';
import 'package:watad/features/evidence/shared/presentation/bloc/evidence_projects_bloc.dart';
import 'package:watad/features/evidence/shared/presentation/pages/evidence_export_page.dart';
import 'package:watad/features/evidence/shared/presentation/pages/evidence_projects_page.dart';

final List<RouteBase> evidenceRoutes = [
  GoRoute(
    name: EvidenceRoutes.evidenceProjectsName,
    path: EvidenceRoutes.evidenceProjectsPath,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<EvidenceProjectsBloc>()..add(const EvidenceProjectsFetched()),
      child: const EvidenceProjectsPage(),
    ),
  ),
  GoRoute(
    name: EvidenceRoutes.evidenceExportName,
    path: EvidenceRoutes.evidenceExportPath,
    builder: (context, state) {
      final projectId = state.pathParameters['projectId']!;
      return BlocProvider(
        create: (_) =>
            getIt<EvidenceExportBloc>()..add(EvidenceExportStarted(projectId)),
        child: EvidenceExportPage(projectId: projectId),
      );
    },
  ),
];
