import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_type.dart';

part 'client_post_project_event.dart';
part 'client_post_project_state.dart';

class ClientPostProjectBloc
    extends Bloc<ClientPostProjectEvent, ClientPostProjectState> {
  ClientPostProjectBloc() : super(const ClientPostProjectState()) {
    on<ClientPostProjectTypeSelected>(_onTypeSelected);
    on<ClientPostProjectStepAdvanced>(_onStepAdvanced);
    on<ClientPostProjectStepRetreated>(_onStepRetreated);
    on<ClientPostProjectReset>(_onReset);
  }

  void _onTypeSelected(
    ClientPostProjectTypeSelected event,
    Emitter<ClientPostProjectState> emit,
  ) {
    emit(state.copyWith(projectType: event.type));
  }

  void _onStepAdvanced(
    ClientPostProjectStepAdvanced event,
    Emitter<ClientPostProjectState> emit,
  ) {
    if (state.currentStep < state.totalSteps) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    }
  }

  void _onStepRetreated(
    ClientPostProjectStepRetreated event,
    Emitter<ClientPostProjectState> emit,
  ) {
    if (state.currentStep > 1) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  void _onReset(
    ClientPostProjectReset event,
    Emitter<ClientPostProjectState> emit,
  ) {
    emit(const ClientPostProjectState());
  }
}
