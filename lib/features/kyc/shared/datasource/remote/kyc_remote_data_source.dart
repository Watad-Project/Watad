import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/kyc/shared/datasource/models/kyc_document_model.dart';
import 'package:watad/features/kyc/shared/domain/entities/kyc_document.dart';

abstract interface class KycRemoteDataSource {
  Future<KycDocumentModel> getDocument(KycDocumentType documentType);
  Stream<KycDocumentModel> watchDocument(KycDocumentType documentType);
}

class KycRemoteDataSourceImpl implements KycRemoteDataSource {
  const KycRemoteDataSourceImpl(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<KycDocumentModel> getDocument(KycDocumentType documentType) async {
    final docTypeString = switch (documentType) {
      KycDocumentType.license => 'license',
      KycDocumentType.deed => 'deed',
    };

    final row = await _supabase
        .from('v_business_documents')
        .select()
        .eq('document_type', docTypeString)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (row != null) {
      return KycDocumentModel.fromJson(row);
    }

    return KycDocumentModel(
      id: '',
      documentType: documentType,
      status: VerificationStatus.pending,
    );
  }

  @override
  Stream<KycDocumentModel> watchDocument(KycDocumentType documentType) {
    final docTypeString = switch (documentType) {
      KycDocumentType.license => 'license',
      KycDocumentType.deed => 'deed',
    };

    return _supabase
        .from('business_documents')
        .stream(primaryKey: ['id'])
        .eq('document_type', docTypeString)
        .map((rows) {
          if (rows.isNotEmpty) {
            return KycDocumentModel.fromJson(rows.first);
          }
          return KycDocumentModel(
            id: '',
            documentType: documentType,
            status: VerificationStatus.pending,
          );
        });
  }
}
