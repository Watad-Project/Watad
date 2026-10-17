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
    final profileRes = await _supabase
        .from('v_my_profile')
        .select('full_name, avatar_path')
        .maybeSingle();

    final identityRes = await _supabase
        .from('v_my_identity')
        .select('phone')
        .maybeSingle();

    final phone = identityRes?['phone'] as String?;
    final isPhoneVerified = phone != null && phone.trim().isNotEmpty;

    final data = Map<String, dynamic>.from(profileRes ?? <String, dynamic>{});
    data['is_phone_verified'] = isPhoneVerified;

    return ClientHomeProfileModel.fromJson(data);
  }

  @override
  Future<List<ClientSuggestedContractorModel>> getSuggestedContractors() async {
    final response = await _supabase
        .from('v_public_profiles')
        .select(
          'id, company_name, avatar_path, specialized_field, is_verified_business, rating_avg, rating_count',
        )
        .eq('is_business', true)
        .order('is_verified_business', ascending: false)
        .order('rating_avg', ascending: false, nullsFirst: false)
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
