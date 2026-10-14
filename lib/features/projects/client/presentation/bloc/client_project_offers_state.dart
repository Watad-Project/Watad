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
    this.acceptedOfferId,
  });

  final ClientProject project;
  final List<ClientProjectOffer> offers;
  final String? acceptedOfferId;

  ClientProjectOffersLoadSuccess copyWith({
    ClientProject? project,
    List<ClientProjectOffer>? offers,
    String? acceptedOfferId,
  }) {
    return ClientProjectOffersLoadSuccess(
      project: project ?? this.project,
      offers: offers ?? this.offers,
      acceptedOfferId: acceptedOfferId ?? this.acceptedOfferId,
    );
  }
}

final class ClientProjectOffersLoadFailure extends ClientProjectOffersState {
  const ClientProjectOffersLoadFailure(this.failure);

  final Failure failure;
}
