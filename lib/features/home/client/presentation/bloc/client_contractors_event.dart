part of 'client_contractors_bloc.dart';

sealed class ClientContractorsEvent {
  const ClientContractorsEvent();
}

/// Load the first page: at the start, on pull to refresh and on retry.
final class ClientContractorsFetched extends ClientContractorsEvent {
  const ClientContractorsFetched();
}

/// The search text or a filter chip changed: start again from the first
/// page.
final class ClientContractorsFilterChanged extends ClientContractorsEvent {
  const ClientContractorsFilterChanged(this.filter);

  final ClientContractorFilter filter;
}

/// The list reached its end: load the next page.
final class ClientContractorsMoreRequested extends ClientContractorsEvent {
  const ClientContractorsMoreRequested();
}
