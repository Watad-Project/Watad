import 'package:watad/features/review/admin/domain/entities/admin_review_kind.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_request.dart';

class AdminReviewRequestModel extends AdminReviewRequest {
  const AdminReviewRequestModel({
    required super.kind,
    required super.id,
    required super.requesterName,
    super.requesterAvatarUrl,
    super.requestedAt,
  });

  /// Maps a row as selected in AdminReviewRemoteDataSourceImpl, plus
  /// `avatar_url`: the public URL the data source made for
  /// `owner_avatar_path`. A `v_admin_deed_queue` row (it has `project_id`)
  /// is a deed; a `v_admin_verification_queue` row is a license.
  factory AdminReviewRequestModel.fromJson(Map<String, dynamic> json) {
    final projectId = json['project_id'] as String?;
    return AdminReviewRequestModel(
      kind: projectId == null ? AdminReviewKind.license : AdminReviewKind.deed,
      id: projectId ?? json['business_id'] as String,
      // The company for a license, the client for a deed.
      requesterName:
          (projectId == null ? json['company_name'] : json['owner_name'])
              as String? ??
          '',
      requesterAvatarUrl: json['avatar_url'] as String?,
      requestedAt: _date(json['requested_at']),
    );
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value) : null;
}
