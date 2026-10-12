import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/onboarding_routes.dart';
import 'package:watad/features/onboarding/shared/presentation/bloc/onboarding_bloc.dart';
import 'package:watad/features/onboarding/shared/presentation/pages/onboarding_page.dart';

final List<RouteBase> onboardingRoutes = [
  GoRoute(
    name: OnboardingRoutes.onboardingName,
    path: OnboardingRoutes.onboardingPath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<OnboardingBloc>(),
      child: const OnboardingPage(),
    ),
  ),
];
