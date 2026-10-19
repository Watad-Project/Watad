import 'package:watad/core/utils/money.dart';
import 'package:watad/features/review/admin/domain/entities/admin_deed_details.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_kind.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_requester.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_target.dart';

class AdminDeedDetailsModel extends AdminDeedDetails {
  const AdminDeedDetailsModel({
    required super.target,
    required super.requester,
    required super.title,
    required super.deedUrl,
    required super.deedPath,
    super.requestedAt,
    super.description,
    super.budget,
    super.city,
    super.district,
    super.photoUrls,
  });

  /// Maps a `v_admin_deed_queue` row as selected in
  /// AdminReviewRemoteDataSourceImpl, plus what the data source made from
  /// it: `deed_url` (a signed URL), `photo_urls` and `owner_avatar_url`.
  factory AdminDeedDetailsModel.fromJson(Map<String, dynamic> json) {
    final budget = json['budget'] as num?;
    return AdminDeedDetailsModel(
      target: AdminReviewTarget(
        kind: AdminReviewKind.deed,
        id: json['project_id'] as String,
      ),
      requester: AdminReviewRequester(
        name: json['owner_name'] as String? ?? '',
        avatarUrl: json['owner_avatar_url'] as String?,
        memberSince: _date(json['member_since']),
      ),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      budget: budget == null ? null : Money.fromJson(budget),
      city: json['city'] as String?,
      district: json['district'] as String?,
      photoUrls: [
        for (final url in json['photo_urls'] as List? ?? const [])
          url as String,
      ],
      deedUrl: json['deed_url'] as String,
      deedPath: json['deed_storage_path'] as String,
      requestedAt: _date(json['requested_at']),
    );
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value) : null;
}
