part of 'client_post_project_bloc.dart';

sealed class ClientPostProjectEvent {
  const ClientPostProjectEvent();
}

/// The user selected a project type on step 1.
final class ClientPostProjectTypeSelected extends ClientPostProjectEvent {
  const ClientPostProjectTypeSelected(this.type);

  final ClientProjectType type;
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
