import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/domain/usecases/get_initial_destination_use_case.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc(
    this._getInitialDestination, {
    this._minimumDuration = defaultMinimumDuration,
  }) : super(const SplashInitial()) {
    on<SplashStarted>(_onStarted);
  }

  /// The destination is known almost at once, so the splash waits at least
  /// this long before it answers. Otherwise it would flash by in one frame.
  static const Duration defaultMinimumDuration = Duration(seconds: 2);

  final GetInitialDestinationUseCase _getInitialDestination;
  final Duration _minimumDuration;
  Timer? _minimumTimer;

  Future<void> _onStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    emit(const SplashLoadInProgress());
    final shownLongEnough = Completer<void>();
    _minimumTimer?.cancel();
    _minimumTimer = Timer(_minimumDuration, shownLongEnough.complete);
    final result = await _getInitialDestination(const NoParams());
    await shownLongEnough.future;
    switch (result) {
      case Success(:final data):
        emit(SplashLoadSuccess(data));
      case Failed(:final failure):
        emit(SplashLoadFailure(failure));
    }
  }

  @override
  Future<void> close() {
    _minimumTimer?.cancel();
    return super.close();
  }
}
