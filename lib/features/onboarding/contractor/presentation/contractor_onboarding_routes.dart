import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/contractor_onboarding_routes.dart';
import 'package:watad/features/onboarding/contractor/presentation/bloc/contractor_specialty_bloc.dart';
import 'package:watad/features/onboarding/contractor/presentation/pages/contractor_specialty_page.dart';

final List<RouteBase> contractorOnboardingRoutes = [
  GoRoute(
    name: ContractorOnboardingRoutes.specialtyName,
    path: ContractorOnboardingRoutes.specialtyPath,
    builder: (context, state) => BlocProvider(
      create: (context) => getIt<ContractorSpecialtyBloc>(),
      child: const ContractorSpecialtyPage(),
    ),
  ),
];
