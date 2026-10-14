part of 'kyc_status_bloc.dart';

sealed class KycStatusEvent {
  const KycStatusEvent();
}

final class KycStatusStarted extends KycStatusEvent {
  const KycStatusStarted({
    this.documentType = BusinessDocumentType.commercialRegistration,
    this.initialStatus,
  });

  final BusinessDocumentType documentType;
  final VerificationStatus? initialStatus;
}

final class KycStatusUpdated extends KycStatusEvent {
  const KycStatusUpdated(this.document);

  final KycDocument document;
}
