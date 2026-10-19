import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/datasource/remote/contractor_work_remote_data_source.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_bid_details.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_contract_project.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_filter.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_overview.dart';
import 'package:watad/features/work/contractor/domain/repositories/contractor_work_repository.dart';

class ContractorWorkRepositoryImpl implements ContractorWorkRepository {
  const ContractorWorkRepositoryImpl(this._remote);

  final ContractorWorkRemoteDataSource _remote;

  @override
  Future<Result<ContractorWorkOverview>> getWorkOverview({
    ContractorWorkFilter filter = const ContractorWorkFilter(),
  }) => guardSupabaseCall(() => _remote.getWorkOverview(filter: filter));

  @override
  Future<Result<List<ContractorContractProject>>> getMyContracts() =>
      guardSupabaseCall(_remote.getMyContracts);

  @override
  Future<Result<ContractorBidDetails>> getBidDetails(String projectId) =>
      guardSupabaseCall(() => _remote.getBidDetails(projectId));

  @override
  Future<Result<void>> submitOffer({
    required String projectId,
    required Money amount,
    required String message,
  }) => guardSupabaseCall(
    () => _remote.submitOffer(
      projectId: projectId,
      amount: amount,
      message: message,
    ),
  );

  @override
  Future<Result<void>> editOffer({
    required String offerId,
    required Money amount,
    required String message,
  }) => guardSupabaseCall(
    () => _remote.editOffer(offerId: offerId, amount: amount, message: message),
  );

  @override
  Future<Result<void>> withdrawOffer(String offerId) =>
      guardSupabaseCall(() => _remote.withdrawOffer(offerId));
}
