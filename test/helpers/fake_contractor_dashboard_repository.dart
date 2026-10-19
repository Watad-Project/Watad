import 'package:flutter/widgets.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/contractor_dashboard_routes.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_profile.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_raw_data.dart';
import 'package:watad/features/dashboard/contractor/domain/repositories/contractor_dashboard_repository.dart';
import 'package:watad/features/dashboard/contractor/domain/usecases/contractor_get_dashboard_data_use_case.dart';
import 'package:watad/features/dashboard/contractor/presentation/bloc/contractor_dashboard_bloc.dart';
import 'package:watad/features/dashboard/contractor/presentation/widgets/contractor_dashboard_tab.dart';

/// A hand-written [ContractorDashboardRepository] for tests
/// (APP_ARCHITECTURE.md §16).
class FakeContractorDashboardRepository
    implements ContractorDashboardRepository {
  const FakeContractorDashboardRepository({
    this.result = const Success(
      ContractorDashboardRawData(
        profile: ContractorDashboardProfile(
          companyName: 'مؤسسة البناء المتين',
          verificationStatus: VerificationStatus.verified,
        ),
        payments: [],
        opportunitiesCount: 6,
        projects: [],
        tasks: [],
        offers: [],
      ),
    ),
  });

  final Result<ContractorDashboardRawData> result;

  @override
  Future<Result<ContractorDashboardRawData>> getDashboardRawData() async =>
      result;
}

/// For tests that open the contractor navigation: the navigation tab takes
/// its [Widget] from getIt under [ContractorDashboardRoutes.dashboardName].
/// Reset getIt after the test.
void registerFakeContractorDashboardTab([
  ContractorDashboardRepository repository =
      const FakeContractorDashboardRepository(),
]) {
  getIt
    ..registerFactory(
      () => ContractorDashboardBloc(
        ContractorGetDashboardDataUseCase(repository),
      ),
    )
    ..registerFactory<Widget>(
      () => ContractorDashboardTab(
        bloc: getIt<ContractorDashboardBloc>()
          ..add(const ContractorDashboardFetched()),
      ),
      instanceName: ContractorDashboardRoutes.dashboardName,
    );
}
