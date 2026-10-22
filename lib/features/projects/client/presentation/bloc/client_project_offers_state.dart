part of 'client_project_offers_bloc.dart';

enum ClientProjectOffersStatus { initial, loading, success, failure }

/// A message to show once after accepting, as a translation key.
final class ClientProjectOffersMessage {
  const ClientProjectOffersMessage(this.key, {required this.isError});

  final String key;
  final bool isError;
}

final class ClientProjectOffersState {
  const ClientProjectOffersState({
    this.status = ClientProjectOffersStatus.initial,
    this.project,
    this.offers = const [],
    this.failure,
    this.acceptingOfferId,
    this.message,
  });

  final ClientProjectOffersStatus status;
  final ClientProject? project;

  /// Cheapest first.
  final List<ClientProjectOffer> offers;

  /// Why the page couldn't load.
  final Failure? failure;

  /// The offer being accepted.
  final String? acceptingOfferId;
  final ClientProjectOffersMessage? message;

  /// Offers can be accepted while the project is open and the offer
  /// pending (the server checks it too).
  bool canAccept(ClientProjectOffer offer) =>
      project?.status == ProjectStatus.open &&
      offer.status == OfferStatus.pending;

  ClientProjectOffersState copyWith({
    ClientProjectOffersStatus? status,
    ClientProject? project,
    List<ClientProjectOffer>? offers,
    Failure? Function()? failure,
    String? Function()? acceptingOfferId,
    ClientProjectOffersMessage? Function()? message,
  }) {
    return ClientProjectOffersState(
      status: status ?? this.status,
      project: project ?? this.project,
      offers: offers ?? this.offers,
      failure: failure == null ? this.failure : failure(),
      acceptingOfferId: acceptingOfferId == null
          ? this.acceptingOfferId
          : acceptingOfferId(),
      message: message == null ? this.message : message(),
    );
  }
}
