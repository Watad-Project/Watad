import 'package:watad/core/error/result.dart';
import 'package:watad/features/home/client/domain/entities/client_contractor.dart';
import 'package:watad/features/home/client/domain/entities/client_contractors_query.dart';
import 'package:watad/features/home/client/domain/entities/client_home_profile.dart';

abstract interface class ClientHomeRepository {
  Future<Result<ClientHomeProfile>> getProfile();

  /// Five verified contractors: the client's city first, then the best
  /// rated.
  Future<Result<List<ClientContractor>>> getSuggestedContractors();

  /// One page of the verified contractors that match the query's filter,
  /// the client's city first, then in the filter's order.
  Future<Result<List<ClientContractor>>> getContractors(
    ClientContractorsQuery query,
  );

  /// The cities verified contractors work in, for the city filter.
  Future<Result<List<String>>> getContractorCities();
}
