import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';
import 'package:watad/features/location/shared/domain/usecases/delete_address_use_case.dart';
import 'package:watad/features/location/shared/domain/usecases/get_saved_addresses_use_case.dart';

part 'location_addresses_event.dart';
part 'location_addresses_state.dart';

/// «عناويني»: my saved addresses, and deleting one. After a delete the list
/// is read again, so it shows what the server has.
class LocationAddressesBloc
    extends Bloc<LocationAddressesEvent, LocationAddressesState> {
  LocationAddressesBloc(this._getAddresses, this._delete)
    : super(const LocationAddressesState()) {
    on<LocationAddressesFetched>(_onFetched);
    on<LocationAddressDeleted>(_onDeleted);
  }

  final GetSavedAddressesUseCase _getAddresses;
  final DeleteAddressUseCase _delete;

  Future<void> _onFetched(
    LocationAddressesFetched event,
    Emitter<LocationAddressesState> emit,
  ) async {
    if (state.addresses == null) {
      emit(state.copyWith(status: LocationAddressesStatus.loading));
    }
    await _load(emit);
  }

  Future<void> _load(Emitter<LocationAddressesState> emit) async {
    switch (await _getAddresses(const NoParams())) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: LocationAddressesStatus.success,
            addresses: () => data,
            failure: () => null,
          ),
        );
      case Failed(:final failure) when state.addresses != null:
        // The list stays on screen; a snackbar says why.
        emit(state.copyWith(actionFailure: () => failure));
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: LocationAddressesStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  Future<void> _onDeleted(
    LocationAddressDeleted event,
    Emitter<LocationAddressesState> emit,
  ) async {
    if (state.deletingId != null) return;
    emit(
      state.copyWith(
        deletingId: () => event.address.id,
        actionFailure: () => null,
        deleted: false,
      ),
    );
    final result = await _delete(event.address);
    emit(
      state.copyWith(
        deletingId: () => null,
        deleted: result is Success<void>,
        actionFailure: () => switch (result) {
          Failed(:final failure) => failure,
          Success() => null,
        },
      ),
    );
    await _load(emit);
  }
}
