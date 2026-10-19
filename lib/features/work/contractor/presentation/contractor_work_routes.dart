import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/contractor_work_routes.dart';
import 'package:watad/features/work/contractor/presentation/bloc/contractor_bid_bloc.dart';
import 'package:watad/features/work/contractor/presentation/bloc/contractor_work_bloc.dart';
import 'package:watad/features/work/contractor/presentation/pages/contractor_bid_page.dart';
import 'package:watad/features/work/contractor/presentation/pages/contractor_work_page.dart';

final List<RouteBase> contractorWorkRoutes = [
  GoRoute(
    name: ContractorWorkRoutes.workName,
    path: ContractorWorkRoutes.workPath,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<ContractorWorkBloc>()..add(const ContractorWorkStarted()),
      child: const ContractorWorkPage(),
    ),
  ),
  GoRoute(
    name: ContractorWorkRoutes.bidName,
    path: ContractorWorkRoutes.bidPath,
    builder: (context, state) {
      final projectId = state.pathParameters['projectId'] ?? '';
      return BlocProvider(
        create: (_) =>
            getIt<ContractorBidBloc>()..add(ContractorBidStarted(projectId)),
        child: ContractorBidPage(projectId: projectId),
      );
    },
  ),
];
