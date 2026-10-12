import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/kyc/shared/domain/entities/kyc_document.dart';
import 'package:watad/features/kyc/shared/domain/repositories/kyc_repository.dart';

/// Fetches the document verification status.
class GetKycDocumentUseCase implements UseCase<KycDocument, KycDocumentType> {
  const GetKycDocumentUseCase(this._repository);

  final KycRepository _repository;

  @override
  Future<Result<KycDocument>> call(KycDocumentType params) =>
      _repository.getDocument(params);
}
