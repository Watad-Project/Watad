import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/review/admin/datasource/models/admin_deed_details_model.dart';
import 'package:watad/features/review/admin/datasource/models/admin_license_details_model.dart';
import 'package:watad/features/review/admin/datasource/models/admin_review_document_model.dart';
import 'package:watad/features/review/admin/datasource/models/admin_review_request_model.dart';

abstract interface class AdminReviewRemoteDataSource {
  /// Pending licenses, oldest first.
  Future<List<AdminReviewRequestModel>> getPendingLicenses();

  /// Deeds under review, oldest first.
  Future<List<AdminReviewRequestModel>> getPendingDeeds();

  Future<AdminLicenseDetailsModel> getLicenseDetails(String businessId);

  Future<AdminDeedDetailsModel> getDeedDetails(String projectId);

  Future<void> setLicenseVerification({
    required String businessId,
    required VerificationStatus status,
    String? note,
  });

  /// Verifies the deed (which publishes its project) or rejects it with
  /// [reason].
  Future<void> setDeedVerification({
    required String projectId,
    required bool verified,
    String? reason,
  });
}

class AdminReviewRemoteDataSourceImpl implements AdminReviewRemoteDataSource {
  const AdminReviewRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  /// How long a document link stays valid.
  static const int _signedUrlSeconds = 10 * 60;

  /// `projects.deed_status` values (ARCHITECTURE.md §4).
  static const String _deedVerified = 'verified';
  static const String _deedRejected = 'rejected';

  @override
  Future<List<AdminReviewRequestModel>> getPendingLicenses() async {
    final rows = await _client
        .from('v_admin_verification_queue')
        .select('business_id, company_name, owner_avatar_path, requested_at')
        .eq('verification_status', VerificationStatus.pending.toJson())
        // Oldest first: a fair queue.
        .order('requested_at', ascending: true);
    return [
      for (final row in rows)
        AdminReviewRequestModel.fromJson({
          ...row,
          'avatar_url': _avatarUrl(row['owner_avatar_path']),
        }),
    ];
  }

  @override
  Future<List<AdminReviewRequestModel>> getPendingDeeds() async {
    final rows = await _client
        .from('v_admin_deed_queue')
        .select('project_id, owner_name, owner_avatar_path, requested_at')
        .order('requested_at', ascending: true);
    return [
      for (final row in rows)
        AdminReviewRequestModel.fromJson({
          ...row,
          'avatar_url': _avatarUrl(row['owner_avatar_path']),
        }),
    ];
  }

  @override
  Future<AdminLicenseDetailsModel> getLicenseDetails(String businessId) async {
    // The queue has only pending rows: a decided license is not found.
    final row = await _client
        .from('v_admin_verification_queue')
        .select(
          'business_id, company_name, cr_number, specialized_field, city, '
          'owner_name, owner_avatar_path, member_since, requested_at',
        )
        .eq('business_id', businessId)
        .single();
    final documents = await _getDocuments(businessId);
    return AdminLicenseDetailsModel.fromJson({
      ...row,
      'owner_avatar_url': _avatarUrl(row['owner_avatar_path']),
      'documents': documents,
    });
  }

  @override
  Future<AdminDeedDetailsModel> getDeedDetails(String projectId) async {
    // The queue has only deeds under review: a decided deed is not found.
    final row = await _client
        .from('v_admin_deed_queue')
        .select(
          'project_id, title, description, budget, city, district, '
          'photo_paths, deed_storage_path, requested_at, owner_name, '
          'owner_avatar_path, member_since',
        )
        .eq('project_id', projectId)
        .single();
    final deedUrl = await _client.storage
        .from('project-deeds')
        .createSignedUrl(row['deed_storage_path'] as String, _signedUrlSeconds);
    final photoPaths = row['photo_paths'] as List? ?? const [];
    return AdminDeedDetailsModel.fromJson({
      ...row,
      'deed_url': deedUrl,
      'photo_urls': [
        for (final path in photoPaths)
          _client.storage.from('images').getPublicUrl(path as String),
      ],
      'owner_avatar_url': _avatarUrl(row['owner_avatar_path']),
    });
  }

  Future<List<AdminReviewDocumentModel>> _getDocuments(
    String businessId,
  ) async {
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
  Future<void> setLicenseVerification({
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

  @override
  Future<void> setDeedVerification({
    required String projectId,
    required bool verified,
    String? reason,
  }) async {
    await _client.rpc<void>(
      'admin_set_project_deed_verification',
      params: {
        'p_project_id': projectId,
        'p_status': verified ? _deedVerified : _deedRejected,
        'p_rejection_reason': reason,
      },
    );
  }

  /// Photos are in the public `avatars` bucket.
  String? _avatarUrl(Object? path) => path is String && path.isNotEmpty
      ? _client.storage.from('avatars').getPublicUrl(path)
      : null;
}
