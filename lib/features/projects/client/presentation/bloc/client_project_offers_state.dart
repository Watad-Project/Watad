part of 'client_project_offers_bloc.dart';

sealed class ClientProjectOffersState {
  const ClientProjectOffersState();
}

final class ClientProjectOffersInitial extends ClientProjectOffersState {
  const ClientProjectOffersInitial();
}

final class ClientProjectOffersLoadInProgress extends ClientProjectOffersState {
  const ClientProjectOffersLoadInProgress();
}

final class ClientProjectOffersLoadSuccess extends ClientProjectOffersState {
  const ClientProjectOffersLoadSuccess({
    required this.project,
    required this.offers,
    this.acceptingOfferId,
  });

  final ClientProject project;
  final List<ClientProjectOffer> offers;
  final String? acceptingOfferId;
}

final class ClientProjectOffersLoadFailure extends ClientProjectOffersState {
  const ClientProjectOffersLoadFailure(this.failure);

  final Failure failure;
}

final class ClientProjectOfferAcceptSuccess extends ClientProjectOffersState {
  const ClientProjectOfferAcceptSuccess({
    required this.project,
    required this.offers,
    required this.offerId,
  });

  final ClientProject project;
  final List<ClientProjectOffer> offers;
  final String offerId;
}

final class ClientProjectOfferAcceptFailure extends ClientProjectOffersState {
  const ClientProjectOfferAcceptFailure({
    required this.project,
    required this.offers,
    required this.failure,
  });

  final ClientProject project;
  final List<ClientProjectOffer> offers;
  final Failure failure;
}
