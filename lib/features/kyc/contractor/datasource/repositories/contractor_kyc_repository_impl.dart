import 'dart:typed_data';

import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/kyc/contractor/datasource/remote/contractor_kyc_remote_data_source.dart';
import 'package:watad/features/kyc/contractor/domain/entities/contractor_license_submission.dart';
import 'package:watad/features/kyc/contractor/domain/repositories/contractor_kyc_repository.dart';

class ContractorKycRepositoryImpl implements ContractorKycRepository {
  const ContractorKycRepositoryImpl(this._remoteDataSource);

  final ContractorKycRemoteDataSource _remoteDataSource;

  @override
  Future<Result<ContractorLicenseSubmission>> uploadLicense({
    required Uint8List bytes,
    required String fileName,
  }) {
    return guardSupabaseCall(
      () => _remoteDataSource.uploadLicense(bytes: bytes, fileName: fileName),
    );
  }

  @override
  Future<Result<void>> signOut() {
    return guardSupabaseCall(_remoteDataSource.signOut);
  }
}
