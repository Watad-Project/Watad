part of 'admin_blockchain_project_bloc.dart';

/// A message to show once after the resync, as a translation key.
final class AdminBlockchainProjectMessage {
  const AdminBlockchainProjectMessage(this.key, {required this.isError});

  final String key;
  final bool isError;
}

final class AdminBlockchainProjectState {
  const AdminBlockchainProjectState({
    this.projectId,
    this.project,
    this.failure,
    this.isBusy = false,
    this.message,
  });

  /// From the route, so a retry knows what to load.
  final String? projectId;

  /// Kept while it loads again.
  final AdminBlockchainProject? project;

  /// Why the project couldn't load.
  final Failure? failure;

  /// The resync is being sent.
  final bool isBusy;
  final AdminBlockchainProjectMessage? message;

  AdminBlockchainProjectState copyWith({
    String? Function()? projectId,
    AdminBlockchainProject? Function()? project,
    Failure? Function()? failure,
    bool? isBusy,
    AdminBlockchainProjectMessage? Function()? message,
  }) {
    return AdminBlockchainProjectState(
      projectId: projectId == null ? this.projectId : projectId(),
      project: project == null ? this.project : project(),
      failure: failure == null ? this.failure : failure(),
      isBusy: isBusy ?? this.isBusy,
      message: message == null ? this.message : message(),
    );
  }
}
