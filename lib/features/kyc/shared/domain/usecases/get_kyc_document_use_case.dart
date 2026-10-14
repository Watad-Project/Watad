import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/kyc/shared/domain/entities/kyc_document.dart';
import 'package:watad/features/kyc/shared/domain/repositories/kyc_repository.dart';

/// Fetches the document verification status.
class GetKycDocumentUseCase
    implements UseCase<KycDocument, BusinessDocumentType> {
  const GetKycDocumentUseCase(this._repository);

  final KycRepository _repository;

  @override
  Future<Result<KycDocument>> call(BusinessDocumentType params) =>
      _repository.getDocument(params);
}
