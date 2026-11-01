import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/contractor_profile_routes.dart';
import 'package:watad/features/profile/contractor/presentation/pages/contractor_profile_page.dart';
import 'package:watad/features/profile/shared/presentation/bloc/profile_overview_bloc.dart';

final List<RouteBase> contractorProfileRoutes = [
  GoRoute(
    name: ContractorProfileRoutes.profileName,
    path: ContractorProfileRoutes.profilePath,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<ProfileOverviewBloc>()..add(const ProfileOverviewFetched()),
      child: const ContractorProfilePage(),
    ),
  ),
];
