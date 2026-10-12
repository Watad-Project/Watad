import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/kyc/shared/domain/entities/kyc_document.dart';
import 'package:watad/features/kyc/shared/domain/repositories/kyc_repository.dart';

/// Subscribes to live document verification status updates via Supabase realtime.
class WatchKycDocumentUseCase
    implements UseCase<Stream<Result<KycDocument>>, KycDocumentType> {
  const WatchKycDocumentUseCase(this._repository);

  final KycRepository _repository;

  @override
  Future<Result<Stream<Result<KycDocument>>>> call(
    KycDocumentType params,
  ) async {
    return Success(_repository.watchDocument(params));
  }
}
