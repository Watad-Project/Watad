import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/home/client/domain/entities/client_home_profile.dart';
import 'package:watad/features/home/client/domain/entities/client_suggested_contractor.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_home_profile_use_case.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_suggested_contractors_use_case.dart';

part 'client_home_event.dart';
part 'client_home_state.dart';

class ClientHomeBloc extends Bloc<ClientHomeEvent, ClientHomeState> {
  ClientHomeBloc(this._getHomeProfile, this._getSuggestedContractors)
    : super(const ClientHomeInitial()) {
    on<ClientHomeStarted>(_onStarted);
    on<ClientHomeRefreshed>(_onRefreshed);
  }

  final ClientGetHomeProfileUseCase _getHomeProfile;
  final ClientGetSuggestedContractorsUseCase _getSuggestedContractors;

  Future<void> _onStarted(
    ClientHomeStarted event,
    Emitter<ClientHomeState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _onRefreshed(
    ClientHomeRefreshed event,
    Emitter<ClientHomeState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _load(Emitter<ClientHomeState> emit) async {
    emit(const ClientHomeLoadInProgress());
    final profileResult = await _getHomeProfile(const NoParams());
    switch (profileResult) {
      case Failed(:final failure):
        emit(ClientHomeLoadFailure(failure));
        return;
      case Success(:final data):
        final contractorsResult = await _getSuggestedContractors(
          const NoParams(),
        );
        final contractors = switch (contractorsResult) {
          Success(data: final list) => list,
          Failed() => const <ClientSuggestedContractor>[],
        };
        emit(ClientHomeLoadSuccess(profile: data, contractors: contractors));
    }
  }
}
