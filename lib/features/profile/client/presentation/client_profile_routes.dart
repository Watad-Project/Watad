import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/client_profile_routes.dart';
import 'package:watad/features/profile/client/presentation/pages/client_profile_page.dart';
import 'package:watad/features/profile/shared/presentation/bloc/profile_overview_bloc.dart';

final List<RouteBase> clientProfileRoutes = [
  GoRoute(
    name: ClientProfileRoutes.profileName,
    path: ClientProfileRoutes.profilePath,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<ProfileOverviewBloc>()..add(const ProfileOverviewFetched()),
      child: const ClientProfilePage(),
    ),
  ),
];
