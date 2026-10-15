import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/kyc/shared/datasource/remote/kyc_remote_data_source.dart';
import 'package:watad/features/kyc/shared/domain/entities/kyc_document.dart';
import 'package:watad/features/kyc/shared/domain/repositories/kyc_repository.dart';

class KycRepositoryImpl implements KycRepository {
  const KycRepositoryImpl(this._remoteDataSource);

  final KycRemoteDataSource _remoteDataSource;

  @override
  Future<Result<KycDocument>> getDocument([
    BusinessDocumentType documentType =
        BusinessDocumentType.commercialRegistration,
  ]) {
    return guardSupabaseCall(() => _remoteDataSource.getDocument(documentType));
  }

  @override
  Stream<Result<KycDocument>> watchDocument([
    BusinessDocumentType documentType =
        BusinessDocumentType.commercialRegistration,
  ]) {
    return guardSupabaseStream(const Stream.empty());
  }
}
