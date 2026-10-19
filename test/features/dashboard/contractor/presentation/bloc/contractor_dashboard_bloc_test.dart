import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_profile.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_raw_data.dart';
import 'package:watad/features/dashboard/contractor/domain/repositories/contractor_dashboard_repository.dart';
import 'package:watad/features/dashboard/contractor/domain/usecases/contractor_get_dashboard_data_use_case.dart';
import 'package:watad/features/dashboard/contractor/presentation/bloc/contractor_dashboard_bloc.dart';

class FakeContractorDashboardRepository
    implements ContractorDashboardRepository {
  FakeContractorDashboardRepository(this.result);

  Result<ContractorDashboardRawData> result;

  @override
  Future<Result<ContractorDashboardRawData>> getDashboardRawData() async =>
      result;
}

void main() {
  const testData = ContractorDashboardRawData(
    profile: ContractorDashboardProfile(
      companyName: 'مؤسسة البناء المتين',
      verificationStatus: VerificationStatus.verified,
    ),
    payments: [],
    opportunitiesCount: 6,
    projects: [],
    tasks: [],
    offers: [],
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
