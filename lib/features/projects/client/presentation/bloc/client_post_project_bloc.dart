import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_deed_verification_status.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_type.dart';
import 'package:watad/features/projects/client/domain/usecases/client_create_project_use_case.dart';

part 'client_post_project_event.dart';
part 'client_post_project_state.dart';

class ClientPostProjectBloc
    extends Bloc<ClientPostProjectEvent, ClientPostProjectState> {
  ClientPostProjectBloc([ClientCreateProjectUseCase? createProjectUseCase])
    : _createProjectUseCase = createProjectUseCase,
      super(const ClientPostProjectState()) {
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
    on<ClientPostProjectSubmitted>(_onSubmitted);
  }

  final ClientCreateProjectUseCase? _createProjectUseCase;

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
    // Keep deed status visibly pending (none) instead of fake underReview
    emit(
      state.copyWith(
        deedFilePath: event.filePath,
        deedFileName: event.fileName,
        deedStatus: ClientDeedVerificationStatus.none,
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

  Future<void> _onSubmitted(
    ClientPostProjectSubmitted event,
    Emitter<ClientPostProjectState> emit,
  ) async {
    emit(state.copyWith(status: ClientPostProjectStatus.submitting));

    if (_createProjectUseCase == null) {
      emit(state.copyWith(status: ClientPostProjectStatus.success));
      return;
    }

    final addressText = state.locationAddress ?? '';
    final parts = addressText.split('·').map((p) => p.trim()).toList();
    final city = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : 'Riyadh';
    final district = parts.length > 1 ? parts[1] : null;

    final typeName = state.projectType?.name ?? 'project';
    final title = state.scopeOfWork.isNotEmpty
        ? state.scopeOfWork.split('\n').first.trim()
        : typeName;

    final result = await _createProjectUseCase(
      ClientNewProject(
        title: title,
        city: city,
        district: district,
        description: state.scopeOfWork.isNotEmpty ? state.scopeOfWork : null,
        budget: state.settledBudget,
        publish: !state.requiresDeed,
      ),
    );

    switch (result) {
      case Success():
        emit(state.copyWith(status: ClientPostProjectStatus.success));
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: ClientPostProjectStatus.failure,
            failure: failure,
          ),
        );
    }
  }
}
