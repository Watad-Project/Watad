import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/profile_routes.dart';
import 'package:watad/features/profile/shared/presentation/bloc/profile_city_search_bloc.dart';
import 'package:watad/features/profile/shared/presentation/bloc/profile_edit_bloc.dart';
import 'package:watad/features/profile/shared/presentation/pages/profile_edit_page.dart';

final List<RouteBase> profileRoutes = [
  // A public profile at '/profile/:userId' (GRA-58) goes after this one,
  // so 'edit' isn't read as a user id.
  GoRoute(
    name: ProfileRoutes.profileEditName,
    path: ProfileRoutes.profileEditPath,
    builder: (context, state) => MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<ProfileEditBloc>()..add(const ProfileEditFetched()),
        ),
        // The city search, for the sheet the city field opens.
        BlocProvider(create: (_) => getIt<ProfileCitySearchBloc>()),
      ],
      child: const ProfileEditPage(),
    ),
  ),
];
