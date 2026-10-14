import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/kyc/shared/domain/entities/kyc_document.dart';

/// Model representing a verification status record from Supabase.
class KycDocumentModel extends KycDocument {
  const KycDocumentModel({
    required super.id,
    required super.status,
    super.documentType,
    super.rejectionReason,
    super.specializedField,
  });

  factory KycDocumentModel.fromJson(Map<String, dynamic> json) {
    final statusStr =
        json['verification_status'] as String? ??
        json['status'] as String? ??
        'unverified';
    final status = VerificationStatus.fromJson(statusStr);

    final rawDocType = json['document_type'] as String?;
    final docType = rawDocType != null
        ? BusinessDocumentType.fromJson(rawDocType)
        : BusinessDocumentType.commercialRegistration;

    return KycDocumentModel(
      id: json['id'] as String? ?? json['user_id'] as String? ?? '',
      status: status,
      documentType: docType,
      rejectionReason: json['rejection_reason'] as String?,
      specializedField: json['specialized_field'] as String?,
    );
  }
}
