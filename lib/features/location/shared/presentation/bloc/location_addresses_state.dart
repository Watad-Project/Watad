part of 'location_addresses_bloc.dart';

enum LocationAddressesStatus { initial, loading, success, failure }

final class LocationAddressesState {
  const LocationAddressesState({
    this.status = LocationAddressesStatus.initial,
    this.addresses,
    this.failure,
    this.deletingId,
    this.deleted = false,
    this.actionFailure,
  });

  final LocationAddressesStatus status;

  /// The last list the server gave; it stays while it loads again.
  final List<LocationAddress>? addresses;

  /// Why the list couldn't load the first time.
  final Failure? failure;

  /// The address being deleted.
  final String? deletingId;

  /// The last delete went through, for its snackbar.
  final bool deleted;

  /// Why a delete or a reload failed.
  final Failure? actionFailure;

  LocationAddressesState copyWith({
    LocationAddressesStatus? status,
    List<LocationAddress>? Function()? addresses,
    Failure? Function()? failure,
    String? Function()? deletingId,
    bool? deleted,
    Failure? Function()? actionFailure,
  }) {
    return LocationAddressesState(
      status: status ?? this.status,
      addresses: addresses == null ? this.addresses : addresses(),
      failure: failure == null ? this.failure : failure(),
      deletingId: deletingId == null ? this.deletingId : deletingId(),
      deleted: deleted ?? this.deleted,
      actionFailure: actionFailure == null
          ? this.actionFailure
          : actionFailure(),
    );
  }
}
