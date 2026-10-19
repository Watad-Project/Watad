part of 'client_project_offers_bloc.dart';

sealed class ClientProjectOffersEvent {
  const ClientProjectOffersEvent();
}

/// Load the project and its offers.
final class ClientProjectOffersFetched extends ClientProjectOffersEvent {
  const ClientProjectOffersFetched(this.projectId);

  final String projectId;
}

/// «قبول العرض», after the client confirmed.
final class ClientProjectOfferAccepted extends ClientProjectOffersEvent {
  const ClientProjectOfferAccepted(this.offer);

  final ClientProjectOffer offer;
}
