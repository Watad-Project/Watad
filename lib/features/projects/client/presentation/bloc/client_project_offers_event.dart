part of 'client_project_offers_bloc.dart';

sealed class ClientProjectOffersEvent {
  const ClientProjectOffersEvent();
}

/// Fetches the project details and all incoming offers for [projectId].
final class ClientProjectOffersFetched extends ClientProjectOffersEvent {
  const ClientProjectOffersFetched(this.projectId);

  final String projectId;
}

/// The client accepted an offer.
final class ClientProjectOfferAccepted extends ClientProjectOffersEvent {
  const ClientProjectOfferAccepted({
    required this.projectId,
    required this.offerId,
    required this.expectedAmount,
  });

  final String projectId;
  final String offerId;
  final Money expectedAmount;
}
