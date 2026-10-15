part of 'kyc_status_bloc.dart';

sealed class KycStatusState {
  const KycStatusState();
}

final class KycStatusInitial extends KycStatusState {
  const KycStatusInitial();
}

final class KycStatusLoadInProgress extends KycStatusState {
  const KycStatusLoadInProgress();
}

final class KycStatusLoadSuccess extends KycStatusState {
  const KycStatusLoadSuccess(this.document);

  final KycDocument document;
}

final class KycStatusLoadFailure extends KycStatusState {
  const KycStatusLoadFailure(this.failure);

  final Failure failure;
}
