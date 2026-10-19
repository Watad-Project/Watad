import 'package:watad/features/review/admin/domain/entities/admin_license_details.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_document.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_kind.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_requester.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_target.dart';

class AdminLicenseDetailsModel extends AdminLicenseDetails {
  const AdminLicenseDetailsModel({
    required super.target,
    required super.requester,
    required super.companyName,
    required super.crNumber,
    required super.documents,
    super.requestedAt,
    super.specializedField,
    super.city,
  });

  /// Maps a `v_admin_verification_queue` row as selected in
  /// AdminReviewRemoteDataSourceImpl, plus what the data source added:
  /// `owner_avatar_url` (the public URL of `owner_avatar_path`) and
  /// `documents` (the business's files, as models).
  factory AdminLicenseDetailsModel.fromJson(Map<String, dynamic> json) {
    return AdminLicenseDetailsModel(
      target: AdminReviewTarget(
        kind: AdminReviewKind.license,
        id: json['business_id'] as String,
      ),
      requester: AdminReviewRequester(
        name: json['owner_name'] as String? ?? '',
        avatarUrl: json['owner_avatar_url'] as String?,
        memberSince: _date(json['member_since']),
      ),
      companyName: json['company_name'] as String,
      crNumber: json['cr_number'] as String,
      specializedField: json['specialized_field'] as String?,
      city: json['city'] as String?,
      requestedAt: _date(json['requested_at']),
      documents: [
        for (final document in json['documents'] as List? ?? const [])
          document as AdminReviewDocument,
      ],
    );
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value) : null;
}
