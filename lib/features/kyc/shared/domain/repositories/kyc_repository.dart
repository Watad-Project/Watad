import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/kyc/shared/domain/entities/kyc_document.dart';

/// Repository for KYC document verification status and realtime updates.
abstract interface class KycRepository {
  /// Fetches the current verification status for [documentType].
  Future<Result<KycDocument>> getDocument([
    BusinessDocumentType documentType =
        BusinessDocumentType.commercialRegistration,
  ]);

  /// Listens to live verification status updates for [documentType].
  Stream<Result<KycDocument>> watchDocument([
    BusinessDocumentType documentType =
        BusinessDocumentType.commercialRegistration,
  ]);

  /// Signs out the current user.
  Future<Result<void>> signOut();
}
