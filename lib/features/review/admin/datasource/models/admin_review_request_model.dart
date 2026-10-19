import 'package:watad/features/review/admin/domain/entities/admin_review_request.dart';

class AdminReviewRequestModel extends AdminReviewRequest {
  const AdminReviewRequestModel({
    required super.businessId,
    required super.companyName,
    required super.documentCount,
    super.ownerName,
    super.requestedAt,
  });

  /// Maps the columns selected in AdminReviewRemoteDataSourceImpl.
  factory AdminReviewRequestModel.fromJson(Map<String, dynamic> json) {
    final requestedAt = json['requested_at'] as String?;
    return AdminReviewRequestModel(
      businessId: json['business_id'] as String,
      companyName: json['company_name'] as String,
      documentCount: json['document_count'] as int? ?? 0,
      ownerName: json['owner_name'] as String?,
      requestedAt: requestedAt == null ? null : DateTime.parse(requestedAt),
    );
  }
}
