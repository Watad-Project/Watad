part of 'client_home_bloc.dart';

enum ClientHomeStatus { initial, loading, success, failure }

final class ClientHomeState {
  const ClientHomeState({
    this.status = ClientHomeStatus.initial,
    this.profile,
    this.failure,
    this.contractorsStatus = ClientHomeStatus.initial,
    this.contractors = const [],
    this.contractorsFailure,
  });

  /// The page: it shows once the profile has loaded.
  final ClientHomeStatus status;
  final ClientHomeProfile? profile;
  final Failure? failure;

  /// The «مقاولون مقترحون» section loads and fails on its own.
  final ClientHomeStatus contractorsStatus;
  final List<ClientContractor> contractors;
  final Failure? contractorsFailure;

  ClientHomeState copyWith({
    ClientHomeStatus? status,
    ClientHomeProfile? profile,
    Failure? Function()? failure,
    ClientHomeStatus? contractorsStatus,
    List<ClientContractor>? contractors,
    Failure? Function()? contractorsFailure,
  }) {
    return ClientHomeState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      failure: failure == null ? this.failure : failure(),
      contractorsStatus: contractorsStatus ?? this.contractorsStatus,
      contractors: contractors ?? this.contractors,
      contractorsFailure: contractorsFailure == null
          ? this.contractorsFailure
          : contractorsFailure(),
    );
  }
}
