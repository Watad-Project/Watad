import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:watad/core/router/routes/client_profile_routes.dart';
import 'package:watad/features/profile/client/presentation/widgets/client_profile_tab.dart';
import 'package:watad/features/profile/shared/presentation/bloc/profile_overview_bloc.dart';

/// Registers the types of lib/features/profile/client/ into [getIt]. The
/// account's own classes come from registerProfileDependencies (shared/).
///
/// Called once during app bootstrap from lib/core/di/injection.dart.
void registerClientProfileDependencies(GetIt getIt) {
  // The client's navigation shows this as its «حسابي» tab.
  getIt.registerFactory<Widget>(
    () => ClientProfileTab(
      bloc: getIt<ProfileOverviewBloc>()..add(const ProfileOverviewFetched()),
    ),
    instanceName: ClientProfileRoutes.profileName,
  );
}
