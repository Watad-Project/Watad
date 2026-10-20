import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/kyc/shared/datasource/models/kyc_document_model.dart';

abstract interface class KycRemoteDataSource {
  Future<KycDocumentModel> getDocument([
    BusinessDocumentType documentType =
        BusinessDocumentType.commercialRegistration,
  ]);

  Future<void> signOut();
}

class KycRemoteDataSourceImpl implements KycRemoteDataSource {
  const KycRemoteDataSourceImpl(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<KycDocumentModel> getDocument([
    BusinessDocumentType documentType =
        BusinessDocumentType.commercialRegistration,
  ]) async {
    final row = await _supabase
        .from('v_my_profile')
        .select('id, verification_status')
        .maybeSingle();

    if (row != null) {
      return KycDocumentModel.fromJson(row);
    }

    return KycDocumentModel(
      id: '',
      documentType: documentType,
      status: VerificationStatus.unverified,
    );
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
