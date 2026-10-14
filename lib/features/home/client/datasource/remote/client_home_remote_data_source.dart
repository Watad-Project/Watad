import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/home/client/datasource/models/client_home_profile_model.dart';
import 'package:watad/features/home/client/datasource/models/client_suggested_contractor_model.dart';

abstract interface class ClientHomeRemoteDataSource {
  Future<ClientHomeProfileModel> getClientHomeProfile();
  Future<List<ClientSuggestedContractorModel>> getSuggestedContractors();
}

class ClientHomeRemoteDataSourceImpl implements ClientHomeRemoteDataSource {
  const ClientHomeRemoteDataSourceImpl(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<ClientHomeProfileModel> getClientHomeProfile() async {
    final response = await _supabase
        .from('v_my_profile')
        .select('full_name, avatar_path')
        .maybeSingle();

    return ClientHomeProfileModel.fromJson(response ?? <String, dynamic>{});
  }

  @override
  Future<List<ClientSuggestedContractorModel>> getSuggestedContractors() async {
    final response = await _supabase
        .from('v_public_profiles')
        .select('id, company_name, avatar_path, specialized_field')
        .limit(10);

    return (response as List<dynamic>)
        .map(
          (row) => ClientSuggestedContractorModel.fromJson(
            row as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
