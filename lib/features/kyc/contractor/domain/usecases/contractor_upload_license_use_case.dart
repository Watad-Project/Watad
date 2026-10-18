import 'dart:typed_data';

import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/kyc/contractor/domain/entities/contractor_license_submission.dart';
import 'package:watad/features/kyc/contractor/domain/repositories/contractor_kyc_repository.dart';

/// Parameters for uploading a contractor license document.
class ContractorUploadLicenseParams {
  const ContractorUploadLicenseParams({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}

/// Validates and uploads a contractor license document.
///
/// Constraints:
/// - Format: JPG, JPEG, or PDF only (rejects HEIC and others).
/// - Size: Up to 10MB (10 * 1024 * 1024 bytes).
class ContractorUploadLicenseUseCase
    implements
        UseCase<ContractorLicenseSubmission, ContractorUploadLicenseParams> {
  const ContractorUploadLicenseUseCase(this._repository);

  final ContractorKycRepository _repository;

  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

  @override
  Future<Result<ContractorLicenseSubmission>> call(
    ContractorUploadLicenseParams params,
  ) async {
    final lowerName = params.fileName.toLowerCase();

    if (lowerName.endsWith('.heic') || lowerName.endsWith('.heif')) {
      return const Failed(
        ValidationFailure('validation.file_type_not_supported'),
      );
    }

    final isJpg = lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg');
    final isPdf = lowerName.endsWith('.pdf');

    if (!isJpg && !isPdf) {
      return const Failed(
        ValidationFailure('validation.file_type_not_supported'),
      );
    }

    if (params.bytes.isEmpty) {
      return const Failed(ValidationFailure('validation.file_required'));
    }

    if (params.bytes.length > maxFileSizeBytes) {
      return const Failed(ValidationFailure('validation.file_too_large'));
    }

    return _repository.uploadLicense(
      bytes: params.bytes,
      fileName: params.fileName,
    );
  }
}
