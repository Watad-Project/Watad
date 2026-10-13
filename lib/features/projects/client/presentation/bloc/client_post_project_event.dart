part of 'client_post_project_bloc.dart';

sealed class ClientPostProjectEvent {
  const ClientPostProjectEvent();
}

/// The user selected or changed a project type.
final class ClientPostProjectTypeSelected extends ClientPostProjectEvent {
  const ClientPostProjectTypeSelected(this.type);

  final ClientProjectType type;
}

/// The user typed or changed the scope of work (step 2).
final class ClientPostProjectScopeChanged extends ClientPostProjectEvent {
  const ClientPostProjectScopeChanged(this.scope);

  final String scope;
}

/// The user changed the minimum budget (step 2).
final class ClientPostProjectMinBudgetChanged extends ClientPostProjectEvent {
  const ClientPostProjectMinBudgetChanged(this.minBudget);

  final int? minBudget;
}

/// The user changed the maximum budget (step 2).
final class ClientPostProjectMaxBudgetChanged extends ClientPostProjectEvent {
  const ClientPostProjectMaxBudgetChanged(this.maxBudget);

  final int? maxBudget;
}

/// The user selected or changed the location address (step 2).
final class ClientPostProjectLocationChanged extends ClientPostProjectEvent {
  const ClientPostProjectLocationChanged(this.location);

  final String location;
}

/// The user added a photo (step 2).
final class ClientPostProjectPhotoAdded extends ClientPostProjectEvent {
  const ClientPostProjectPhotoAdded(this.photo);

  final String photo;
}

/// The user removed a photo by index (step 2).
final class ClientPostProjectPhotoRemoved extends ClientPostProjectEvent {
  const ClientPostProjectPhotoRemoved(this.index);

  final int index;
}

/// The user selected or uploaded a property ownership deed document (step 3).
final class ClientPostProjectDeedSelected extends ClientPostProjectEvent {
  const ClientPostProjectDeedSelected({required this.filePath, this.fileName});

  final String filePath;
  final String? fileName;
}

/// The deed verification status changed (step 3).
final class ClientPostProjectDeedStatusChanged extends ClientPostProjectEvent {
  const ClientPostProjectDeedStatusChanged(this.status, {this.rejectionReason});

  final ClientDeedVerificationStatus status;
  final String? rejectionReason;
}

/// The user tapped re-upload after a deed was rejected (step 3).
final class ClientPostProjectDeedRetry extends ClientPostProjectEvent {
  const ClientPostProjectDeedRetry();
}

/// The user advanced to the next step.
final class ClientPostProjectStepAdvanced extends ClientPostProjectEvent {
  const ClientPostProjectStepAdvanced();
}

/// The user moved back to the previous step.
final class ClientPostProjectStepRetreated extends ClientPostProjectEvent {
  const ClientPostProjectStepRetreated();
}

/// Resets the post-project flow back to step 1.
final class ClientPostProjectReset extends ClientPostProjectEvent {
  const ClientPostProjectReset();
}
