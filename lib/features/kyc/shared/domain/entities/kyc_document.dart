import 'package:watad/core/enums/verification_status.dart';

/// The document type being verified (contractor license or property deed).
enum KycDocumentType { license, deed }

/// A document verification record.
class KycDocument {
  const KycDocument({
    required this.id,
    required this.documentType,
    required this.status,
    this.rejectionReason,
    this.specializedField,
  });

  final String id;
  final KycDocumentType documentType;
  final VerificationStatus status;
  final String? rejectionReason;
  final String? specializedField;
}
