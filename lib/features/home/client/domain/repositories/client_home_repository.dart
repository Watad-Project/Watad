import 'package:watad/core/error/result.dart';
import 'package:watad/features/home/client/domain/entities/client_home_profile.dart';
import 'package:watad/features/home/client/domain/entities/client_suggested_contractor.dart';

abstract interface class ClientHomeRepository {
  Future<Result<ClientHomeProfile>> getClientHomeProfile();
  Future<Result<List<ClientSuggestedContractor>>> getSuggestedContractors();
}
