import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/features/projects/client/domain/entities/client_deed_verification_status.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_type.dart';

part 'client_post_project_event.dart';
part 'client_post_project_state.dart';

class ClientPostProjectBloc
    extends Bloc<ClientPostProjectEvent, ClientPostProjectState> {
  ClientPostProjectBloc() : super(const ClientPostProjectState()) {
    on<ClientPostProjectTypeSelected>(_onTypeSelected);
    on<ClientPostProjectScopeChanged>(_onScopeChanged);
    on<ClientPostProjectMinBudgetChanged>(_onMinBudgetChanged);
    on<ClientPostProjectMaxBudgetChanged>(_onMaxBudgetChanged);
    on<ClientPostProjectLocationChanged>(_onLocationChanged);
    on<ClientPostProjectPhotoAdded>(_onPhotoAdded);
    on<ClientPostProjectPhotoRemoved>(_onPhotoRemoved);
    on<ClientPostProjectDeedSelected>(_onDeedSelected);
    on<ClientPostProjectDeedStatusChanged>(_onDeedStatusChanged);
    on<ClientPostProjectDeedRetry>(_onDeedRetry);
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

  void _onScopeChanged(
    ClientPostProjectScopeChanged event,
    Emitter<ClientPostProjectState> emit,
  ) {
    emit(state.copyWith(scopeOfWork: event.scope));
  }

  void _onMinBudgetChanged(
    ClientPostProjectMinBudgetChanged event,
    Emitter<ClientPostProjectState> emit,
  ) {
    emit(state.copyWith(minBudget: event.minBudget));
  }

  void _onMaxBudgetChanged(
    ClientPostProjectMaxBudgetChanged event,
    Emitter<ClientPostProjectState> emit,
  ) {
    emit(state.copyWith(maxBudget: event.maxBudget));
  }

  void _onLocationChanged(
    ClientPostProjectLocationChanged event,
    Emitter<ClientPostProjectState> emit,
  ) {
    emit(state.copyWith(locationAddress: event.location));
  }

  void _onPhotoAdded(
    ClientPostProjectPhotoAdded event,
    Emitter<ClientPostProjectState> emit,
  ) {
    emit(state.copyWith(photos: [...state.photos, event.photo]));
  }

  void _onPhotoRemoved(
    ClientPostProjectPhotoRemoved event,
    Emitter<ClientPostProjectState> emit,
  ) {
    final updated = [...state.photos]..removeAt(event.index);
    emit(state.copyWith(photos: updated));
  }

  void _onDeedSelected(
    ClientPostProjectDeedSelected event,
    Emitter<ClientPostProjectState> emit,
  ) {
    emit(
      state.copyWith(
        deedFilePath: event.filePath,
        deedFileName: event.fileName,
        deedStatus: ClientDeedVerificationStatus.underReview,
        clearDeed: false,
      ),
    );
  }

  void _onDeedStatusChanged(
    ClientPostProjectDeedStatusChanged event,
    Emitter<ClientPostProjectState> emit,
  ) {
    emit(
      state.copyWith(
        deedStatus: event.status,
        deedRejectionReason: event.rejectionReason,
      ),
    );
  }

  void _onDeedRetry(
    ClientPostProjectDeedRetry event,
    Emitter<ClientPostProjectState> emit,
  ) {
    emit(
      state.copyWith(
        clearDeed: true,
        deedStatus: ClientDeedVerificationStatus.none,
      ),
    );
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
