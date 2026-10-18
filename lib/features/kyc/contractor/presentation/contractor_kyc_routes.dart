import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/contractor_kyc_routes.dart';
import 'package:watad/features/kyc/contractor/presentation/bloc/contractor_license_bloc.dart';
import 'package:watad/features/kyc/contractor/presentation/pages/contractor_license_page.dart';

final List<RouteBase> contractorKycRoutes = [
  GoRoute(
    name: ContractorKycRoutes.licenseName,
    path: ContractorKycRoutes.licensePath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<ContractorLicenseBloc>(),
      child: const ContractorLicensePage(),
    ),
  ),
];
