import 'package:watad/core/error/result.dart';
import 'package:watad/features/home/client/domain/entities/client_contractor.dart';
import 'package:watad/features/home/client/domain/entities/client_contractors_query.dart';
import 'package:watad/features/home/client/domain/entities/client_home_profile.dart';

abstract interface class ClientHomeRepository {
  Future<Result<ClientHomeProfile>> getProfile();

  /// The five best rated verified contractors, highest first.
  Future<Result<List<ClientContractor>>> getSuggestedContractors();

  /// One page of the verified contractors that match the query's filter,
  /// best rated first.
  Future<Result<List<ClientContractor>>> getContractors(
    ClientContractorsQuery query,
  );
}
