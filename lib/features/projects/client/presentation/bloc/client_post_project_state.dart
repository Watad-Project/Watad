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
    this.addressId,
    this.locationCity,
    this.locationDistrict,
    this.savedAddresses = const [],
    this.isLoadingAddresses = false,
    this.selectedAddress,
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

  /// The minimum budget (step 2).
  final Money? minBudget;

  /// The maximum budget (step 2).
  final Money? maxBudget;

  /// Settles budget for saving to Supabase (uses maxBudget, or minBudget).
  Money? get settledBudget => maxBudget ?? minBudget;

  /// The chosen project location / address string (step 2).
  final String? locationAddress;

  /// Foreign key id of the chosen address in Supabase `addresses` table.
  final String? addressId;

  /// City of the chosen address.
  final String? locationCity;

  /// District of the chosen address.
  final String? locationDistrict;

  /// The client's saved addresses loaded from Supabase `v_my_addresses`.
  final List<ClientSavedAddress> savedAddresses;

  /// Whether saved addresses are currently being loaded from Supabase.
  final bool isLoadingAddresses;

  /// The currently selected saved address.
  final ClientSavedAddress? selectedAddress;

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

  /// Total number of steps based on project type.
  /// 4 steps for New House & Renovation (requires property deed).
  /// 3 steps for Home Repairs (no deed required).
  /// Details, the deed when the type needs one, then the review.
  int get totalSteps => requiresDeed ? 3 : 2;

  /// Whether current project type requires property ownership deed upload.
  bool get requiresDeed => projectType?.requiresDeed ?? true;

  /// Whether the details step (the first) is complete: type, scope, budget
  /// and location.
  bool get canProceedFromDetails {
    if (projectType == null) return false;
    final validScope = scopeOfWork.trim().isNotEmpty;
    final validBudget =
        isBudgetValid &&
        (minBudget == null || minBudget!.halalas > 0) &&
        (maxBudget == null || maxBudget!.halalas > 0);
    final validLocation =
        locationAddress != null && locationAddress!.trim().isNotEmpty;
    return validScope && validBudget && validLocation;
  }

  /// Whether the deed step is complete: a deed picked or uploaded.
  bool get canProceedFromDeed =>
      deedFilePath != null ||
      deedFileName != null ||
      deedStatus == ClientDeedVerificationStatus.underReview ||
      deedStatus == ClientDeedVerificationStatus.verified;

  /// Whether the user is currently on the final review & publish step.
  bool get isReviewStep => currentStep == totalSteps;

  /// Whether the project is ready to be published.
  bool get canPublish {
    if (requiresDeed) return canProceedFromDetails && canProceedFromDeed;
    return canProceedFromDetails;
  }

  /// Whether the current budget fields satisfy min <= max.
  bool get isBudgetValid {
    if (minBudget == null || maxBudget == null) return true;
    return maxBudget!.halalas >= minBudget!.halalas;
  }

  ClientPostProjectState copyWith({
    int? currentStep,
    ClientProjectType? projectType,
    String? scopeOfWork,
    Money? minBudget,
    Money? maxBudget,
    String? locationAddress,
    String? addressId,
    String? locationCity,
    String? locationDistrict,
    List<ClientSavedAddress>? savedAddresses,
    bool? isLoadingAddresses,
    ClientSavedAddress? selectedAddress,
    bool clearSelectedAddress = false,
    List<String>? photos,
    String? deedFilePath,
    String? deedFileName,
    ClientDeedVerificationStatus? deedStatus,
    String? deedRejectionReason,
    bool clearDeed = false,
    bool clearFailure = false,
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
      addressId: addressId ?? this.addressId,
      locationCity: locationCity ?? this.locationCity,
      locationDistrict: locationDistrict ?? this.locationDistrict,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      isLoadingAddresses: isLoadingAddresses ?? this.isLoadingAddresses,
      selectedAddress: clearSelectedAddress
          ? null
          : (selectedAddress ?? this.selectedAddress),
      photos: photos ?? this.photos,
      deedFilePath: clearDeed ? null : (deedFilePath ?? this.deedFilePath),
      deedFileName: clearDeed ? null : (deedFileName ?? this.deedFileName),
      deedStatus: deedStatus ?? this.deedStatus,
      deedRejectionReason: clearDeed
          ? null
          : (deedRejectionReason ?? this.deedRejectionReason),
      status: status ?? this.status,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
