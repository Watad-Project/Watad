part of 'client_post_project_bloc.dart';

/// Form status of the post-project flow.
enum ClientPostProjectStatus { initial, submitting, success, failure }

/// State of the post-project flow across all steps.
final class ClientPostProjectState {
  const ClientPostProjectState({
    this.currentStep = 1,
    this.projectType,
    this.status = ClientPostProjectStatus.initial,
    this.failure,
  });

  /// The active step in the flow (1-indexed).
  final int currentStep;

  /// The selected project type.
  final ClientProjectType? projectType;

  /// Status of operations (initial, submitting, success, failure).
  final ClientPostProjectStatus status;

  /// Any failure that occurred.
  final Failure? failure;

  /// Total steps in the flow based on the chosen type, or 4 by default.
  int get totalSteps => projectType?.totalSteps ?? 4;

  /// Whether the project type requires an ownership deed.
  bool get requiresDeed => projectType?.requiresDeed ?? true;

  /// Whether step 1 is valid to proceed to step 2.
  bool get canProceedFromStep1 => projectType != null;

  ClientPostProjectState copyWith({
    int? currentStep,
    ClientProjectType? projectType,
    ClientPostProjectStatus? status,
    Failure? failure,
  }) {
    return ClientPostProjectState(
      currentStep: currentStep ?? this.currentStep,
      projectType: projectType ?? this.projectType,
      status: status ?? this.status,
      failure: failure ?? this.failure,
    );
  }
}
