import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_document.dart';

class AdminReviewDocumentModel extends AdminReviewDocument {
  const AdminReviewDocumentModel({
    required super.id,
    required super.documentType,
    required super.storagePath,
    required super.createdAt,
    required super.url,
  });

  /// Maps the columns selected in AdminReviewRemoteDataSourceImpl, plus
  /// `url`: the signed URL the data source made for `storage_path`.
  factory AdminReviewDocumentModel.fromJson(Map<String, dynamic> json) {
    return AdminReviewDocumentModel(
      id: json['id'] as String,
      documentType: BusinessDocumentType.fromJson(
        json['document_type'] as String,
      ),
      storagePath: json['storage_path'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      url: json['url'] as String,
    );
  }
}
