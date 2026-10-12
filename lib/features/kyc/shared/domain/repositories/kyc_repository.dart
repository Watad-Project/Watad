import 'package:watad/core/error/result.dart';
import 'package:watad/features/kyc/shared/domain/entities/kyc_document.dart';

/// Repository for KYC document verification status and realtime updates.
abstract interface class KycRepository {
  /// Fetches the current verification document for [documentType].
  Future<Result<KycDocument>> getDocument(KycDocumentType documentType);

  /// Listens to live updates for [documentType].
  Stream<Result<KycDocument>> watchDocument(KycDocumentType documentType);
}
