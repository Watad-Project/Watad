import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/home/client/domain/entities/client_contractor.dart';
import 'package:watad/features/home/client/domain/entities/client_home_profile.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_home_profile_use_case.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_suggested_contractors_use_case.dart';

part 'client_home_event.dart';
part 'client_home_state.dart';

/// The client's home: who they are, and the suggested contractors.
class ClientHomeBloc extends Bloc<ClientHomeEvent, ClientHomeState> {
  ClientHomeBloc(this._getProfile, this._getContractors)
    : super(const ClientHomeState()) {
    on<ClientHomeStarted>((event, emit) async {
      emit(
        state.copyWith(
          status: ClientHomeStatus.loading,
          contractorsStatus: ClientHomeStatus.loading,
        ),
      );
      await Future.wait([_loadProfile(emit), _loadContractors(emit)]);
    });
    on<ClientHomeRefreshed>(
      (event, emit) =>
          Future.wait([_loadProfile(emit), _loadContractors(emit)]),
    );
    on<ClientHomeContractorsRetried>((event, emit) async {
      emit(state.copyWith(contractorsStatus: ClientHomeStatus.loading));
      await _loadContractors(emit);
    });
  }

  final ClientGetHomeProfileUseCase _getProfile;
  final ClientGetSuggestedContractorsUseCase _getContractors;

  Future<void> _loadProfile(Emitter<ClientHomeState> emit) async {
    final result = await _getProfile(const NoParams());
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: ClientHomeStatus.success,
            profile: data,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: ClientHomeStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  Future<void> _loadContractors(Emitter<ClientHomeState> emit) async {
    final result = await _getContractors(const NoParams());
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            contractorsStatus: ClientHomeStatus.success,
            contractors: data,
            contractorsFailure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            contractorsStatus: ClientHomeStatus.failure,
            contractorsFailure: () => failure,
          ),
        );
    }
  }
}
