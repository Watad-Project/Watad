import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/contractor_payments_routes.dart';
import 'package:watad/features/payments/contractor/presentation/bloc/contractor_bank_details_bloc.dart';
import 'package:watad/features/payments/contractor/presentation/pages/contractor_bank_details_page.dart';

final List<RouteBase> contractorPaymentsRoutes = [
  GoRoute(
    name: ContractorPaymentsRoutes.bankDetailsName,
    path: ContractorPaymentsRoutes.bankDetailsPath,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<ContractorBankDetailsBloc>()
            ..add(const ContractorBankDetailsFetched()),
      child: const ContractorBankDetailsPage(),
    ),
  ),
];
