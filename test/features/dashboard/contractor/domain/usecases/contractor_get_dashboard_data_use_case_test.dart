import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_data.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_earnings.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_profile.dart';
import 'package:watad/features/dashboard/contractor/domain/repositories/contractor_dashboard_repository.dart';
import 'package:watad/features/dashboard/contractor/domain/usecases/contractor_get_dashboard_data_use_case.dart';

class FakeContractorDashboardRepository
    implements ContractorDashboardRepository {
  FakeContractorDashboardRepository(this.result);

  final Result<ContractorDashboardData> result;

  @override
  Future<Result<ContractorDashboardData>> getDashboardData() async => result;
}

void main() {
  test('returns dashboard data from repository', () async {
    const data = ContractorDashboardData(
      profile: ContractorDashboardProfile(
        companyName: 'مؤسسة البناء المتين',
        verificationStatus: VerificationStatus.verified,
      ),
      earnings: ContractorDashboardEarnings(
        thisMonthEarnings: Money.halalas(100000),
        pendingTransfers: Money.zero(),
      ),
      opportunitiesCount: 3,
      activeProjects: [],
      myOffers: [],
    );

    final useCase = ContractorGetDashboardDataUseCase(
      FakeContractorDashboardRepository(const Success(data)),
    );

    final result = await useCase(const NoParams());

    expect(result, isA<Success<ContractorDashboardData>>());
    final success = result as Success<ContractorDashboardData>;
    expect(success.data.opportunitiesCount, 3);
  });
}
