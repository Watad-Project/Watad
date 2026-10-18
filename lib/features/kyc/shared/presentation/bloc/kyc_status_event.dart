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

final class KycStatusRefreshed extends KycStatusEvent {
  const KycStatusRefreshed({
    this.documentType = BusinessDocumentType.commercialRegistration,
    this.completer,
  });

  final BusinessDocumentType documentType;
  final Completer<void>? completer;
}

final class KycStatusUpdated extends KycStatusEvent {
  const KycStatusUpdated(this.document);

  final KycDocument document;
}
