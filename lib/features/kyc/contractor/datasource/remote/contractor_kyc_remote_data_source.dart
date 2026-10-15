import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/features/kyc/contractor/datasource/models/contractor_license_submission_model.dart';

abstract interface class ContractorKycRemoteDataSource {
  Future<ContractorLicenseSubmissionModel> uploadLicense({
    required Uint8List bytes,
    required String fileName,
  });
}

class ContractorKycRemoteDataSourceImpl
    implements ContractorKycRemoteDataSource {
  const ContractorKycRemoteDataSourceImpl(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<ContractorLicenseSubmissionModel> uploadLicense({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null || user.id.isEmpty) {
      throw const AuthException(
        'User must be authenticated to upload a license',
        statusCode: '401',
      );
    }
    final userId = user.id;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = '$userId/${timestamp}_$cleanFileName';

    await _supabase.storage
        .from('business-documents')
        .uploadBinary(storagePath, bytes);

    await _supabase.from('business_documents').insert({
      'document_type': BusinessDocumentType.commercialRegistration.value,
      'storage_path': storagePath,
    });

    await _supabase.rpc<void>('request_business_verification');

    return ContractorLicenseSubmissionModel(storagePath: storagePath);
  }
}
