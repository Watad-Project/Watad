import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/onboarding/shared/domain/usecases/mark_onboarding_seen_use_case.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc(this._markOnboardingSeen) : super(const OnboardingInitial()) {
    on<OnboardingFinished>(_onFinished);
  }

  final MarkOnboardingSeenUseCase _markOnboardingSeen;

  Future<void> _onFinished(
    OnboardingFinished event,
    Emitter<OnboardingState> emit,
  ) async {
    // A second tap while saving, or after it, changes nothing.
    if (state is OnboardingSaveInProgress || state is OnboardingSaveSuccess) {
      return;
    }
    emit(const OnboardingSaveInProgress());
    final result = await _markOnboardingSeen(const NoParams());
    switch (result) {
      case Success():
        emit(const OnboardingSaveSuccess());
      case Failed(:final failure):
        emit(OnboardingSaveFailure(failure));
    }
  }
}
