import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/support_routes.dart';
import 'package:watad/features/support/shared/domain/entities/support_target.dart';
import 'package:watad/features/support/shared/presentation/bloc/support_new_report_bloc.dart';
import 'package:watad/features/support/shared/presentation/bloc/support_reports_bloc.dart';
import 'package:watad/features/support/shared/presentation/pages/support_new_report_page.dart';
import 'package:watad/features/support/shared/presentation/pages/support_reports_page.dart';

final List<RouteBase> supportRoutes = [
  GoRoute(
    name: SupportRoutes.supportReportsName,
    path: SupportRoutes.supportReportsPath,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<SupportReportsBloc>()..add(const SupportReportsFetched()),
      child: const SupportReportsPage(),
    ),
  ),
  GoRoute(
    name: SupportRoutes.supportNewReportName,
    path: SupportRoutes.supportNewReportPath,
    builder: (context, state) {
      final query = state.uri.queryParameters;
      final kind = SupportTargetKind.named(query['target']);
      final id = query['id'];
      return BlocProvider(
        create: (_) => getIt<SupportNewReportBloc>(),
        child: SupportNewReportPage(
          target: kind == null || id == null || id.isEmpty
              ? null
              : SupportTarget(kind: kind, id: id),
        ),
      );
    },
  ),
];
