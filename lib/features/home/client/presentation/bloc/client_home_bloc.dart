import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/home/client/domain/entities/client_home_profile.dart';
import 'package:watad/features/home/client/domain/entities/client_suggested_contractor.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_home_profile_use_case.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_suggested_contractors_use_case.dart';

part 'client_home_event.dart';
part 'client_home_state.dart';

class ClientHomeBloc extends Bloc<ClientHomeEvent, ClientHomeState> {
  ClientHomeBloc(
    this._getHomeProfileUseCase,
    this._getSuggestedContractorsUseCase,
  ) : super(const ClientHomeState()) {
    on<ClientHomeStarted>(_onStarted);
    on<ClientHomeRefreshed>(_onRefreshed);
  }

  final ClientGetHomeProfileUseCase _getHomeProfileUseCase;
  final ClientGetSuggestedContractorsUseCase _getSuggestedContractorsUseCase;

  Future<void> _onStarted(
    ClientHomeStarted event,
    Emitter<ClientHomeState> emit,
  ) async {
    emit(state.copyWith(status: ClientHomeStatus.loading));
    await _fetchData(emit);
  }

  Future<void> _onRefreshed(
    ClientHomeRefreshed event,
    Emitter<ClientHomeState> emit,
  ) async {
    await _fetchData(emit);
  }

  Future<void> _fetchData(Emitter<ClientHomeState> emit) async {
    final profileResult = await _getHomeProfileUseCase(const NoParams());
    final contractorsResult = await _getSuggestedContractorsUseCase(
      const NoParams(),
    );

    if (profileResult is Failed<ClientHomeProfile>) {
      emit(
        state.copyWith(
          status: ClientHomeStatus.failure,
          errorMessageKey: profileResult.failure.messageKey,
        ),
      );
      return;
    }

    final profile = (profileResult as Success<ClientHomeProfile>).data;
    final contractors = switch (contractorsResult) {
      Success<List<ClientSuggestedContractor>>(:final data) => data,
      Failed<List<ClientSuggestedContractor>>() =>
        <ClientSuggestedContractor>[],
    };

    emit(
      state.copyWith(
        status: ClientHomeStatus.success,
        profile: profile,
        suggestedContractors: contractors,
      ),
    );
  }
}
