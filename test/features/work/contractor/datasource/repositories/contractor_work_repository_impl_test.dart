import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/datasource/models/contractor_bid_details_model.dart';
import 'package:watad/features/work/contractor/datasource/models/contractor_contract_project_model.dart';
import 'package:watad/features/work/contractor/datasource/models/contractor_work_overview_model.dart';
import 'package:watad/features/work/contractor/datasource/remote/contractor_work_remote_data_source.dart';
import 'package:watad/features/work/contractor/datasource/repositories/contractor_work_repository_impl.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_bid_details.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_contract_project.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_overview.dart';

class _FakeRemoteDataSource implements ContractorWorkRemoteDataSource {
  _FakeRemoteDataSource({
    this.model,
    this.contracts = const [],
    this.bidModel,
    this.error,
  });

  final ContractorWorkOverviewModel? model;
  final List<ContractorContractProjectModel> contracts;
  final ContractorBidDetailsModel? bidModel;
  final Object? error;

  String? submittedProjectId;
  Money? submittedAmount;
  String? submittedMessage;

  String? editedOfferId;
  Money? editedAmount;
  String? editedMessage;

  String? withdrawnOfferId;

  @override
  Future<ContractorWorkOverviewModel> getWorkOverview() async {
    if (error != null) throw error!;
    return model!;
  }

  @override
  Future<List<ContractorContractProjectModel>> getMyContracts() async {
    if (error != null) throw error!;
    return contracts;
  }

  @override
  Future<ContractorBidDetailsModel> getBidDetails(String projectId) async {
    if (error != null) throw error!;
    return bidModel!;
  }

  @override
  Future<void> submitOffer({
    required String projectId,
    required Money amount,
    required String message,
  }) async {
    if (error != null) throw error!;
    submittedProjectId = projectId;
    submittedAmount = amount;
    submittedMessage = message;
  }

  @override
  Future<void> editOffer({
    required String offerId,
    required Money amount,
    required String message,
  }) async {
    if (error != null) throw error!;
    editedOfferId = offerId;
    editedAmount = amount;
    editedMessage = message;
  }

  @override
  Future<void> withdrawOffer(String offerId) async {
    if (error != null) throw error!;
    withdrawnOfferId = offerId;
  }
}

void main() {
  group('ContractorWorkRepositoryImpl', () {
    test('returns Success when remote getWorkOverview succeeds', () async {
      const expected = ContractorWorkOverviewModel(
        openProjects: [],
        contractsCount: 2,
      );
      final repository = ContractorWorkRepositoryImpl(
        _FakeRemoteDataSource(model: expected),
      );

      final result = await repository.getWorkOverview();

      expect(result, isA<Success<ContractorWorkOverview>>());
      final data = (result as Success<ContractorWorkOverview>).data;
      expect(data.contractsCount, 2);
      expect(data.openProjects, isEmpty);
    });

    test('getMyContracts returns Success when remote succeeds', () async {
      final contract = ContractorContractProjectModel(
        id: 'contract-1',
        title: 'بناء فيلا سكنية',
        status: ProjectStatus.inProgress,
        ownerName: 'عبدالله الحربي',
        agreedAmount: const Money.halalas(48000000),
        totalPaid: const Money.halalas(21600000),
        city: 'الرياض',
        createdAt: DateTime.utc(2026, 10, 10),
      );
      final repository = ContractorWorkRepositoryImpl(
        _FakeRemoteDataSource(contracts: [contract]),
      );

      final result = await repository.getMyContracts();

      expect(result, isA<Success<List<ContractorContractProject>>>());
      final data = (result as Success<List<ContractorContractProject>>).data;
      expect(data, hasLength(1));
      expect(data.single.id, 'contract-1');
    });

    test(
      'maps PostgrestException into Failed through guardSupabaseCall',
      () async {
        final repository = ContractorWorkRepositoryImpl(
          _FakeRemoteDataSource(
            error: const PostgrestException(message: 'permission denied'),
          ),
        );

        final result = await repository.getWorkOverview();

        expect(result, isA<Failed<ContractorWorkOverview>>());
        expect(
          (result as Failed<ContractorWorkOverview>).failure,
          isA<ServerFailure>(),
        );
      },
    );

    test('getBidDetails returns Success with ContractorBidDetails', () async {
      const expectedBid = ContractorBidDetailsModel(
        verificationStatus: VerificationStatus.verified,
      );
      final repository = ContractorWorkRepositoryImpl(
        _FakeRemoteDataSource(bidModel: expectedBid),
      );

      final result = await repository.getBidDetails('proj-1');

      expect(result, isA<Success<ContractorBidDetails>>());
      final details = (result as Success<ContractorBidDetails>).data;
      expect(details.isVerified, isTrue);
    });

    test(
      'submitOffer, editOffer, and withdrawOffer delegate to remote',
      () async {
        final remote = _FakeRemoteDataSource();
        final repository = ContractorWorkRepositoryImpl(remote);

        final submitRes = await repository.submitOffer(
          projectId: 'proj-1',
          amount: const Money.halalas(500000),
          message: 'جاهزون للتنفيذ.',
        );
        expect(submitRes, isA<Success<void>>());
        expect(remote.submittedProjectId, 'proj-1');
        expect(remote.submittedAmount, const Money.halalas(500000));
        expect(remote.submittedMessage, 'جاهزون للتنفيذ.');

        final editRes = await repository.editOffer(
          offerId: 'offer-1',
          amount: const Money.halalas(480000),
          message: 'عرض محدث.',
        );
        expect(editRes, isA<Success<void>>());
        expect(remote.editedOfferId, 'offer-1');
        expect(remote.editedAmount, const Money.halalas(480000));
        expect(remote.editedMessage, 'عرض محدث.');

        final withdrawRes = await repository.withdrawOffer('offer-1');
        expect(withdrawRes, isA<Success<void>>());
        expect(remote.withdrawnOfferId, 'offer-1');
      },
    );
  });
}
