import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/kyc/shared/domain/entities/kyc_document.dart';

/// Model representing a KYC verification document row from Supabase.
class KycDocumentModel extends KycDocument {
  const KycDocumentModel({
    required super.id,
    required super.documentType,
    required super.status,
    super.rejectionReason,
    super.specializedField,
  });

  factory KycDocumentModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'pending';
    final status = switch (statusStr) {
      'verified' => VerificationStatus.verified,
      'rejected' => VerificationStatus.rejected,
      'suspended' => VerificationStatus.suspended,
      'unverified' => VerificationStatus.unverified,
      _ => VerificationStatus.pending,
    };

    final rawDocType = json['document_type'] as String? ?? 'license';
    final documentType = switch (rawDocType) {
      'deed' => KycDocumentType.deed,
      _ => KycDocumentType.license,
    };

    return KycDocumentModel(
      id: json['id'] as String? ?? '',
      documentType: documentType,
      status: status,
      rejectionReason: json['rejection_reason'] as String?,
      specializedField: json['specialized_field'] as String?,
    );
  }
}
