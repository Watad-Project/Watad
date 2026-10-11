import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/domain/usecases/get_initial_destination_use_case.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc(this._getInitialDestination) : super(const SplashInitial()) {
    on<SplashStarted>(_onStarted);
  }

  final GetInitialDestinationUseCase _getInitialDestination;

  Future<void> _onStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    emit(const SplashLoadInProgress());
    final result = await _getInitialDestination(const NoParams());
    switch (result) {
      case Success(:final data):
        emit(SplashLoadSuccess(data));
      case Failed(:final failure):
        emit(SplashLoadFailure(failure));
    }
  }
}
