import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:watad/core/router/routes/contractor_profile_routes.dart';
import 'package:watad/features/profile/contractor/presentation/widgets/contractor_profile_tab.dart';
import 'package:watad/features/profile/shared/presentation/bloc/profile_overview_bloc.dart';

/// Registers the types of lib/features/profile/contractor/ into [getIt]. The
/// account's own classes come from registerProfileDependencies (shared/).
///
/// Called once during app bootstrap from lib/core/di/injection.dart.
void registerContractorProfileDependencies(GetIt getIt) {
  // The contractor's navigation shows this as its «منشأتي» tab.
  getIt.registerFactory<Widget>(
    () => ContractorProfileTab(
      bloc: getIt<ProfileOverviewBloc>()..add(const ProfileOverviewFetched()),
    ),
    instanceName: ContractorProfileRoutes.profileName,
  );
}
