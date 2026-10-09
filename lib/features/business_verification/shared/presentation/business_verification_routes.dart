import 'package:go_router/go_router.dart';
import 'package:watad/core/router/app_routes.dart';
import 'package:watad/features/business_verification/shared/presentation/pages/verification_status_page.dart';

final List<RouteBase> businessVerificationRoutes = [
  GoRoute(
    name: AppRoutes.verificationStatusName,
    path: AppRoutes.verificationStatusPath,
    builder: (context, state) => const VerificationStatusPage(),
  ),
];
