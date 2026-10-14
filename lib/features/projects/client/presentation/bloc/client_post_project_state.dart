part of 'client_post_project_bloc.dart';

/// Form status of the post-project flow.
enum ClientPostProjectStatus { initial, submitting, success, failure }

/// State of the post-project flow across all steps.
final class ClientPostProjectState {
  const ClientPostProjectState({
    this.currentStep = 1,
    this.projectType,
    this.scopeOfWork = '',
    this.minBudget,
    this.maxBudget,
    this.locationAddress,
    this.photos = const [],
    this.deedFilePath,
    this.deedFileName,
    this.deedStatus = ClientDeedVerificationStatus.none,
    this.deedRejectionReason,
    this.status = ClientPostProjectStatus.initial,
    this.failure,
  });

  /// The active step in the flow (1-indexed).
  final int currentStep;

  /// The selected project type.
  final ClientProjectType? projectType;

  /// The entered scope of work (step 2).
  final String scopeOfWork;

  /// The minimum budget in SAR (step 2).
  final int? minBudget;

  /// The maximum budget in SAR (step 2).
  final int? maxBudget;

  /// The chosen project location / address string (step 2).
  final String? locationAddress;

  /// Attached photo labels or file paths (step 2).
  final List<String> photos;

  /// Local path or remote storage URL of the ownership deed (step 3).
  final String? deedFilePath;

  /// Name of the deed file (step 3).
  final String? deedFileName;

  /// Deed verification lifecycle status (step 3).
  final ClientDeedVerificationStatus deedStatus;

  /// Reason why the deed was rejected, if status is rejected (step 3).
  final String? deedRejectionReason;

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

  /// Whether step 2 is valid to proceed to step 3 (or review).
  bool get canProceedFromStep2 {
    final validScope = scopeOfWork.trim().isNotEmpty;
    final validBudget =
        isBudgetValid &&
        (minBudget == null || minBudget! > 0) &&
        (maxBudget == null || maxBudget! > 0);
    final validLocation =
        locationAddress == null || locationAddress!.trim().isNotEmpty;
    return validScope && validBudget && validLocation;
  }

  /// Whether step 3 is valid to proceed to step 4 (review).
  /// For deed projects, requires deed to be uploaded (underReview or verified).
  bool get canProceedFromStep3 =>
      deedFilePath != null ||
      deedStatus == ClientDeedVerificationStatus.underReview ||
      deedStatus == ClientDeedVerificationStatus.verified;

  /// Whether the user is currently on the final review & publish step.
  bool get isReviewStep => currentStep == totalSteps;

  /// Whether the project is ready to be published.
  bool get canPublish {
    final validStep2 = canProceedFromStep2;
    if (requiresDeed) {
      return validStep2 && canProceedFromStep3;
    }
    return validStep2;
  }

  /// Whether the current budget fields satisfy min <= max.
  bool get isBudgetValid {
    if (minBudget == null || maxBudget == null) return true;
    return maxBudget! >= minBudget!;
  }

  ClientPostProjectState copyWith({
    int? currentStep,
    ClientProjectType? projectType,
    String? scopeOfWork,
    int? minBudget,
    int? maxBudget,
    String? locationAddress,
    List<String>? photos,
    String? deedFilePath,
    String? deedFileName,
    ClientDeedVerificationStatus? deedStatus,
    String? deedRejectionReason,
    bool clearDeed = false,
    ClientPostProjectStatus? status,
    Failure? failure,
  }) {
    return ClientPostProjectState(
      currentStep: currentStep ?? this.currentStep,
      projectType: projectType ?? this.projectType,
      scopeOfWork: scopeOfWork ?? this.scopeOfWork,
      minBudget: minBudget ?? this.minBudget,
      maxBudget: maxBudget ?? this.maxBudget,
      locationAddress: locationAddress ?? this.locationAddress,
      photos: photos ?? this.photos,
      deedFilePath: clearDeed ? null : (deedFilePath ?? this.deedFilePath),
      deedFileName: clearDeed ? null : (deedFileName ?? this.deedFileName),
      deedStatus: deedStatus ?? this.deedStatus,
      deedRejectionReason: clearDeed
          ? null
          : (deedRejectionReason ?? this.deedRejectionReason),
      status: status ?? this.status,
      failure: failure ?? this.failure,
    );
  }
}
