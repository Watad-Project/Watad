import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/home/client/datasource/models/client_home_profile_model.dart';
import 'package:watad/features/home/client/datasource/models/client_suggested_contractor_model.dart';

abstract interface class ClientHomeRemoteDataSource {
  Future<ClientHomeProfileModel> getProfile();

  Future<List<ClientSuggestedContractorModel>> getSuggestedContractors();
}

class ClientHomeRemoteDataSourceImpl implements ClientHomeRemoteDataSource {
  const ClientHomeRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<ClientHomeProfileModel> getProfile() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      return const ClientHomeProfileModel(
        id: 'demo-client-1',
        fullName: '\u0639\u0628\u062f\u0627\u0644\u0644\u0647 \u0627\u0644\u062d\u0631\u0628\u064a',
        isPhoneVerified: true,
      );
    }
    final data = await _client
        .from('v_my_profile')
        .select('id, full_name, avatar_path')
        .single();
    final isPhoneVerified = currentUser.phone != null;
    return ClientHomeProfileModel.fromJson({
      ...data,
      'is_phone_verified': isPhoneVerified,
    });
  }

  @override
  Future<List<ClientSuggestedContractorModel>> getSuggestedContractors() async {
    if (_client.auth.currentUser == null) {
      return _demoContractors;
    }
    final rows = await _client
        .from('v_public_profiles')
        .select('id, company_name, avatar_path, specialized_field')
        .limit(10);
    if (rows.isEmpty) {
      return _demoContractors;
    }
    return rows.map(ClientSuggestedContractorModel.fromJson).toList();
  }

  static const List<ClientSuggestedContractorModel> _demoContractors = [
    ClientSuggestedContractorModel(
      id: 'contractor-1',
      companyName: '\u0627\u0644\u0628\u0646\u0627\u0621 \u0627\u0644\u0645\u062a\u064a\u0646',
      ratingLabel: '\u0664\u066c\u0668',
      projectsLabel: '\u0666\u0664 \u0645\u0634\u0631\u0648\u0639',
      isVerified: true,
    ),
    ClientSuggestedContractorModel(
      id: 'contractor-2',
      companyName: '\u0625\u062a\u0642\u0627\u0646 \u0644\u0644\u062a\u0634\u064a\u064a\u062f',
      ratingLabel: '\u0664\u066c\u0667',
      projectsLabel: '\u0664\u0661 \u0645\u0634\u0631\u0648\u0639',
      isVerified: true,
    ),
  ];
}
