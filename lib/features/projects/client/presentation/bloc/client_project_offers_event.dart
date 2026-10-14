part of 'client_project_offers_bloc.dart';

sealed class ClientProjectOffersEvent {
  const ClientProjectOffersEvent();
}

final class ClientProjectOffersFetched extends ClientProjectOffersEvent {
  const ClientProjectOffersFetched(this.projectId);

  final String projectId;
}

final class ClientProjectOfferAccepted extends ClientProjectOffersEvent {
  const ClientProjectOfferAccepted({
    required this.offerId,
    required this.expectedAmount,
  });

  final String offerId;
  final Money expectedAmount;
}
