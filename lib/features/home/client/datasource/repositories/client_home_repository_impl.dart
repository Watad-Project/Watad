import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/home/client/datasource/remote/client_home_remote_data_source.dart';
import 'package:watad/features/home/client/domain/entities/client_home_profile.dart';
import 'package:watad/features/home/client/domain/entities/client_suggested_contractor.dart';
import 'package:watad/features/home/client/domain/repositories/client_home_repository.dart';

class ClientHomeRepositoryImpl implements ClientHomeRepository {
  const ClientHomeRepositoryImpl(this._remote);

  final ClientHomeRemoteDataSource _remote;

  @override
  Future<Result<ClientHomeProfile>> getProfile() =>
      guardSupabaseCall(_remote.getProfile);

  @override
  Future<Result<List<ClientSuggestedContractor>>> getSuggestedContractors() =>
      guardSupabaseCall(_remote.getSuggestedContractors);
}
