part of 'client_home_bloc.dart';

sealed class ClientHomeState {
  const ClientHomeState();
}

final class ClientHomeInitial extends ClientHomeState {
  const ClientHomeInitial();
}

final class ClientHomeLoadInProgress extends ClientHomeState {
  const ClientHomeLoadInProgress();
}

final class ClientHomeLoadSuccess extends ClientHomeState {
  const ClientHomeLoadSuccess({
    required this.profile,
    required this.contractors,
  });

  final ClientHomeProfile profile;
  final List<ClientSuggestedContractor> contractors;
}

final class ClientHomeLoadFailure extends ClientHomeState {
  const ClientHomeLoadFailure(this.failure);

  final Failure failure;
}
