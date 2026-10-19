import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/review/admin/datasource/models/admin_review_document_model.dart';
import 'package:watad/features/review/admin/datasource/models/admin_review_request_model.dart';

abstract interface class AdminReviewRemoteDataSource {
  Future<List<AdminReviewRequestModel>> getPendingRequests();

  Future<List<AdminReviewDocumentModel>> getDocuments(String businessId);

  Future<void> setVerification({
    required String businessId,
    required VerificationStatus status,
    String? note,
  });
}

class AdminReviewRemoteDataSourceImpl implements AdminReviewRemoteDataSource {
  const AdminReviewRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  /// How long a document link stays valid.
  static const int _signedUrlSeconds = 10 * 60;

  @override
  Future<List<AdminReviewRequestModel>> getPendingRequests() async {
    final rows = await _client
        .from('v_admin_verification_queue')
        .select(
          'business_id, company_name, owner_name, requested_at, '
          'document_count',
        )
        .eq('verification_status', VerificationStatus.pending.toJson())
        // Oldest first: a fair queue.
        .order('requested_at', ascending: true);
    return rows.map(AdminReviewRequestModel.fromJson).toList();
  }

  @override
  Future<List<AdminReviewDocumentModel>> getDocuments(String businessId) async {
    final rows = await _client
        .from('v_business_documents')
        .select('id, document_type, storage_path, created_at')
        .eq('business_id', businessId)
        .order('created_at', ascending: true);
    return Future.wait(
      rows.map((row) async {
        final url = await _client.storage
            .from('business-documents')
            .createSignedUrl(row['storage_path'] as String, _signedUrlSeconds);
        return AdminReviewDocumentModel.fromJson({...row, 'url': url});
      }),
    );
  }

  @override
  Future<void> setVerification({
    required String businessId,
    required VerificationStatus status,
    String? note,
  }) async {
    await _client.rpc<void>(
      'admin_set_business_verification',
      params: {
        'p_business_id': businessId,
        'p_status': status.toJson(),
        'p_note': note,
      },
    );
  }
}
