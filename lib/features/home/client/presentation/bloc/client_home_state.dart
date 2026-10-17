part of 'client_home_bloc.dart';

enum ClientHomeStatus { initial, loading, success, failure }

final class ClientHomeState {
  const ClientHomeState({
    this.status = ClientHomeStatus.initial,
    this.profile,
    this.suggestedContractors = const [],
    this.errorMessageKey,
  });

  final ClientHomeStatus status;
  final ClientHomeProfile? profile;
  final List<ClientSuggestedContractor> suggestedContractors;
  final String? errorMessageKey;

  ClientHomeState copyWith({
    ClientHomeStatus? status,
    ClientHomeProfile? profile,
    List<ClientSuggestedContractor>? suggestedContractors,
    String? errorMessageKey,
  }) {
    return ClientHomeState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      suggestedContractors: suggestedContractors ?? this.suggestedContractors,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
    );
  }
}
