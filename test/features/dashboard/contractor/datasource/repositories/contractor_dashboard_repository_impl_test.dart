import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_profile_model.dart';
import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_raw_data_model.dart';
import 'package:watad/features/dashboard/contractor/datasource/remote/contractor_dashboard_remote_data_source.dart';
import 'package:watad/features/dashboard/contractor/datasource/repositories/contractor_dashboard_repository_impl.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_raw_data.dart';

class FakeContractorDashboardRemoteDataSource
    implements ContractorDashboardRemoteDataSource {
  FakeContractorDashboardRemoteDataSource({this.data, this.error});

  final ContractorDashboardRawDataModel? data;
  final Object? error;

  @override
  Future<ContractorDashboardRawDataModel> getDashboardRawData() async {
    final error = this.error;
    if (error != null) throw error;
    return data!;
  }
}

void main() {
  test('returns data on remote success', () async {
    final remote = FakeContractorDashboardRemoteDataSource(
      data: const ContractorDashboardRawDataModel(
        profile: ContractorDashboardProfileModel(
          companyName: 'مؤسسة البناء',
          verificationStatus: VerificationStatus.verified,
        ),
        payments: [],
        opportunitiesCount: 2,
        projects: [],
        tasks: [],
        offers: [],
      ),
    );

    final repository = ContractorDashboardRepositoryImpl(remote);
    final result = await repository.getDashboardRawData();

    expect(result, isA<Success<ContractorDashboardRawData>>());
    final success = result as Success<ContractorDashboardRawData>;
    expect(success.data.profile.companyName, 'مؤسسة البناء');
  });

  test('returns Failed on remote exception', () async {
    final remote = FakeContractorDashboardRemoteDataSource(
      error: Exception('network error'),
    );

    final repository = ContractorDashboardRepositoryImpl(remote);
    final result = await repository.getDashboardRawData();

    expect(result, isA<Failed<ContractorDashboardRawData>>());
    final failed = result as Failed<ContractorDashboardRawData>;
    expect(failed.failure, isA<UnknownFailure>());
  });
}
