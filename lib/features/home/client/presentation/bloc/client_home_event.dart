part of 'client_home_bloc.dart';

sealed class ClientHomeEvent {
  const ClientHomeEvent();
}

final class ClientHomeStarted extends ClientHomeEvent {
  const ClientHomeStarted();
}

final class ClientHomeRefreshed extends ClientHomeEvent {
  const ClientHomeRefreshed();
}
