import 'package:flutter/widgets.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/contractor_work_routes.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_bid_details.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_contract_project.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_filter.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_overview.dart';
import 'package:watad/features/work/contractor/domain/repositories/contractor_work_repository.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_edit_offer_use_case.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_get_bid_details_use_case.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_get_my_contracts_use_case.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_get_work_overview_use_case.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_submit_offer_use_case.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_withdraw_offer_use_case.dart';
import 'package:watad/features/work/contractor/presentation/bloc/contractor_bid_bloc.dart';
import 'package:watad/features/work/contractor/presentation/bloc/contractor_work_bloc.dart';
import 'package:watad/features/work/contractor/presentation/widgets/contractor_work_tab.dart';

/// A hand-written [ContractorWorkRepository] for tests
/// (APP_ARCHITECTURE.md §16).
class FakeContractorWorkRepository implements ContractorWorkRepository {
  const FakeContractorWorkRepository({
    this.result = const Success(
      ContractorWorkOverview(openProjects: [], contractsCount: 0),
    ),
    this.contractsResult = const Success([]),
    this.bidDetailsResult = const Success(
      ContractorBidDetails(verificationStatus: VerificationStatus.verified),
    ),
    this.submitOfferResult = const Success(null),
    this.editOfferResult = const Success(null),
    this.withdrawOfferResult = const Success(null),
  });

  final Result<ContractorWorkOverview> result;
  final Result<List<ContractorContractProject>> contractsResult;
  final Result<ContractorBidDetails> bidDetailsResult;
  final Result<void> submitOfferResult;
  final Result<void> editOfferResult;
  final Result<void> withdrawOfferResult;

  @override
  Future<Result<ContractorWorkOverview>> getWorkOverview({
    ContractorWorkFilter filter = const ContractorWorkFilter(),
  }) async => result;

  @override
  Future<Result<List<ContractorContractProject>>> getMyContracts() async =>
      contractsResult;

  @override
  Future<Result<ContractorBidDetails>> getBidDetails(String projectId) async =>
      bidDetailsResult;

  @override
  Future<Result<void>> submitOffer({
    required String projectId,
    required Money amount,
    required String message,
  }) async => submitOfferResult;

  @override
  Future<Result<void>> editOffer({
    required String offerId,
    required Money amount,
    required String message,
  }) async => editOfferResult;

  @override
  Future<Result<void>> withdrawOffer(String offerId) async =>
      withdrawOfferResult;
}

/// For tests that open the contractor navigation: the navigation tab takes
/// its [Widget] from getIt under [ContractorWorkRoutes.workName].
/// Reset getIt after the test.
void registerFakeContractorWorkTab([
  ContractorWorkRepository repository = const FakeContractorWorkRepository(),
]) {
  getIt
    ..registerLazySingleton(() => ContractorGetMyContractsUseCase(repository))
    ..registerFactory(
      () => ContractorWorkBloc(ContractorGetWorkOverviewUseCase(repository)),
    )
    ..registerFactory(
      () => ContractorBidBloc(
        ContractorGetBidDetailsUseCase(repository),
        ContractorSubmitOfferUseCase(repository),
        ContractorEditOfferUseCase(repository),
        ContractorWithdrawOfferUseCase(repository),
      ),
    )
    ..registerFactory<Widget>(
      () => ContractorWorkTab(
        bloc: getIt<ContractorWorkBloc>()..add(const ContractorWorkStarted()),
      ),
      instanceName: ContractorWorkRoutes.workName,
    );
}
