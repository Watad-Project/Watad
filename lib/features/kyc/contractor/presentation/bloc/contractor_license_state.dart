part of 'contractor_license_bloc.dart';

sealed class ContractorLicenseState {
  const ContractorLicenseState();
}

final class ContractorLicenseInitial extends ContractorLicenseState {
  const ContractorLicenseInitial();
}

final class ContractorLicenseReady extends ContractorLicenseState {
  const ContractorLicenseReady({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

final class ContractorLicenseLoadInProgress extends ContractorLicenseState {
  const ContractorLicenseLoadInProgress();
}

final class ContractorLicenseLoadSuccess extends ContractorLicenseState {
  const ContractorLicenseLoadSuccess(this.submission);

  final ContractorLicenseSubmission submission;
}

final class ContractorLicenseLoadFailure extends ContractorLicenseState {
  const ContractorLicenseLoadFailure(this.failure);

  final Failure failure;
}

final class ContractorLicenseSignOutSuccess extends ContractorLicenseState {
  const ContractorLicenseSignOutSuccess();
}
