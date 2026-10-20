part of 'contractor_license_bloc.dart';

sealed class ContractorLicenseEvent {
  const ContractorLicenseEvent();
}

final class ContractorLicenseFileSelected extends ContractorLicenseEvent {
  const ContractorLicenseFileSelected({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}

final class ContractorLicenseSubmitted extends ContractorLicenseEvent {
  const ContractorLicenseSubmitted();
}

final class ContractorLicenseSignedOut extends ContractorLicenseEvent {
  const ContractorLicenseSignedOut();
}
