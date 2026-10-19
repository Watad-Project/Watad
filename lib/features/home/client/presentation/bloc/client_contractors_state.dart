part of 'client_contractors_bloc.dart';

enum ClientContractorsStatus { initial, loading, success, failure }

final class ClientContractorsState {
  const ClientContractorsState({
    this.status = ClientContractorsStatus.initial,
    this.filter = const ClientContractorFilter(),
    this.contractors = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
    this.failure,
  });

  final ClientContractorsStatus status;
  final ClientContractorFilter filter;

  /// The pages loaded so far, best rated first.
  final List<ClientContractor> contractors;

  /// Whether another page may follow.
  final bool hasMore;
  final bool isLoadingMore;

  /// Why the first page couldn't load.
  final Failure? failure;

  ClientContractorsState copyWith({
    ClientContractorsStatus? status,
    ClientContractorFilter? filter,
    List<ClientContractor>? contractors,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? Function()? failure,
  }) {
    return ClientContractorsState(
      status: status ?? this.status,
      filter: filter ?? this.filter,
      contractors: contractors ?? this.contractors,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: failure == null ? this.failure : failure(),
    );
  }
}
