import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/core/enums/verification_status.dart';

/// A verification status record.
class KycDocument {
  const KycDocument({
    required this.id,
    required this.status,
    this.documentType = BusinessDocumentType.commercialRegistration,
    this.rejectionReason,
    this.specializedField,
  });

  final String id;
  final VerificationStatus status;
  final BusinessDocumentType documentType;
  final String? rejectionReason;
  final String? specializedField;
}
