part of 'client_home_bloc.dart';

sealed class ClientHomeEvent {
  const ClientHomeEvent();
}

/// Load everything, when the tab opens.
final class ClientHomeStarted extends ClientHomeEvent {
  const ClientHomeStarted();
}

/// Pull to refresh: load again, keeping what is on screen meanwhile.
final class ClientHomeRefreshed extends ClientHomeEvent {
  const ClientHomeRefreshed();
}

/// "Try again" on the contractors section.
final class ClientHomeContractorsRetried extends ClientHomeEvent {
  const ClientHomeContractorsRetried();
}
