import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_bid_details.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_contract_project.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_filter.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_overview.dart';

abstract interface class ContractorWorkRepository {
  Future<Result<ContractorWorkOverview>> getWorkOverview({
    ContractorWorkFilter filter = const ContractorWorkFilter(),
  });

  Future<Result<List<ContractorContractProject>>> getMyContracts();

  Future<Result<ContractorBidDetails>> getBidDetails(String projectId);

  Future<Result<void>> submitOffer({
    required String projectId,
    required Money amount,
    required String message,
  });

  Future<Result<void>> editOffer({
    required String offerId,
    required Money amount,
    required String message,
  });

  Future<Result<void>> withdrawOffer(String offerId);
}
