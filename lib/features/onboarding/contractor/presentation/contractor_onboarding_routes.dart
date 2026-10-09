import 'package:go_router/go_router.dart';
import 'package:watad/core/router/app_routes.dart';
import 'package:watad/features/onboarding/contractor/presentation/pages/contractor_specialty_page.dart';

final List<RouteBase> contractorOnboardingRoutes = [
  GoRoute(
    name: AppRoutes.contractorSpecialtyName,
    path: AppRoutes.contractorSpecialtyPath,
    builder: (context, state) => const ContractorSpecialtyPage(),
  ),
];
