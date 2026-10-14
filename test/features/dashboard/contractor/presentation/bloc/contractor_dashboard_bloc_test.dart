import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_data.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_earnings.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_profile.dart';
import 'package:watad/features/dashboard/contractor/domain/repositories/contractor_dashboard_repository.dart';
import 'package:watad/features/dashboard/contractor/domain/usecases/contractor_get_dashboard_data_use_case.dart';
import 'package:watad/features/dashboard/contractor/presentation/bloc/contractor_dashboard_bloc.dart';

class FakeContractorDashboardRepository
    implements ContractorDashboardRepository {
  FakeContractorDashboardRepository(this.result);

  Result<ContractorDashboardData> result;

  @override
  Future<Result<ContractorDashboardData>> getDashboardData() async => result;
}

void main() {
  const testData = ContractorDashboardData(
    profile: ContractorDashboardProfile(
      companyName: 'مؤسسة البناء المتين',
      verificationStatus: VerificationStatus.verified,
    ),
    earnings: ContractorDashboardEarnings(
      thisMonthEarnings: Money.halalas(1250000),
      pendingTransfers: Money.halalas(320000),
    ),
    opportunitiesCount: 6,
    activeProjects: [],
    myOffers: [],
  );

  test('emits LoadInProgress then LoadSuccess on successful fetch', () async {
    final repository = FakeContractorDashboardRepository(
      const Success(testData),
    );
    final bloc = ContractorDashboardBloc(
      ContractorGetDashboardDataUseCase(repository),
    );

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ContractorDashboardLoadInProgress>(),
        isA<ContractorDashboardLoadSuccess>().having(
          (s) => s.data.profile.companyName,
          'companyName',
          'مؤسسة البناء المتين',
        ),
      ]),
    );

    bloc.add(const ContractorDashboardFetched());
    await states;
    await bloc.close();
  });

  test('emits LoadInProgress then LoadFailure on failed fetch', () async {
    final repository = FakeContractorDashboardRepository(
      const Failed(NetworkFailure()),
    );
    final bloc = ContractorDashboardBloc(
      ContractorGetDashboardDataUseCase(repository),
    );

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ContractorDashboardLoadInProgress>(),
        isA<ContractorDashboardLoadFailure>().having(
          (s) => s.failure,
          'failure',
          isA<NetworkFailure>(),
        ),
      ]),
    );

    bloc.add(const ContractorDashboardFetched());
    await states;
    await bloc.close();
  });

  test(
    'refreshed emits LoadSuccess without re-emitting LoadInProgress',
    () async {
      final repository = FakeContractorDashboardRepository(
        const Success(testData),
      );
      final bloc = ContractorDashboardBloc(
        ContractorGetDashboardDataUseCase(repository),
      );

      final states = expectLater(
        bloc.stream,
        emitsInOrder([isA<ContractorDashboardLoadSuccess>()]),
      );

      bloc.add(const ContractorDashboardRefreshed());
      await states;
      await bloc.close();
    },
  );
}
