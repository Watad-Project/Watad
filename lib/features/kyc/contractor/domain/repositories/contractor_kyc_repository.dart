import 'dart:typed_data';

import 'package:watad/core/error/result.dart';
import 'package:watad/features/kyc/contractor/domain/entities/contractor_license_submission.dart';

/// Repository for contractor KYC license document upload and verification.
abstract interface class ContractorKycRepository {
  /// Uploads the contractor license document bytes to the private
  /// `business-documents` bucket, records the document in the database,
  /// and requests business verification.
  Future<Result<ContractorLicenseSubmission>> uploadLicense({
    required Uint8List bytes,
    required String fileName,
  });

  /// Signs out the current contractor.
  Future<Result<void>> signOut();
}
