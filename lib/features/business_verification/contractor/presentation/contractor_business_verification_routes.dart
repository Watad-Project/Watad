import 'package:go_router/go_router.dart';
import 'package:watad/core/router/app_routes.dart';
import 'package:watad/features/business_verification/contractor/presentation/pages/contractor_license_upload_page.dart';

final List<RouteBase> contractorBusinessVerificationRoutes = [
  GoRoute(
    name: AppRoutes.contractorLicenseUploadName,
    path: AppRoutes.contractorLicenseUploadPath,
    builder: (context, state) => const ContractorLicenseUploadPage(),
  ),
];
