import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/admin_reports_routes.dart';
import 'package:watad/features/reports/admin/presentation/bloc/admin_reports_bloc.dart';
import 'package:watad/features/reports/admin/presentation/pages/admin_reports_page.dart';

final List<RouteBase> adminReportsRoutes = [
  GoRoute(
    name: AdminReportsRoutes.reportsName,
    path: AdminReportsRoutes.reportsPath,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<AdminReportsBloc>()..add(const AdminReportsFetched()),
      child: const AdminReportsPage(),
    ),
  ),
];
