part of 'admin_blockchain_bloc.dart';

enum AdminBlockchainStatus { initial, loading, success, failure }

enum AdminBlockchainHealthStatus { initial, checking, success, failure }

final class AdminBlockchainState {
  const AdminBlockchainState({
    this.status = AdminBlockchainStatus.initial,
    this.overview,
    this.failure,
    this.filter = AdminBlockchainFilter.all,
    this.healthStatus = AdminBlockchainHealthStatus.initial,
    this.health,
    this.healthFailure,
  });

  /// The summary and the projects, kept while they load again.
  final AdminBlockchainStatus status;
  final AdminBlockchainOverview? overview;
  final Failure? failure;

  final AdminBlockchainFilter filter;

  /// The ledger's last check, kept while it runs again.
  final AdminBlockchainHealthStatus healthStatus;
  final AdminBlockchainHealth? health;

  /// Why the check itself couldn't run (not: the ledger is down).
  final Failure? healthFailure;

  /// The projects of the selected chip, those that need attention first.
  List<AdminBlockchainProject> get visibleProjects => [
    for (final project
        in overview?.projects ?? const <AdminBlockchainProject>[])
      if (filter.matches(project)) project,
  ];

  /// The number on [filter]'s chip.
  int countOf(AdminBlockchainFilter filter) =>
      (overview?.projects ?? const <AdminBlockchainProject>[])
          .where(filter.matches)
          .length;

  /// Null until the summary loaded.
  AdminBlockchainOverall? get overall => switch (overview) {
    final overview? => AdminBlockchainOverall.of(overview.summary, health),
    null => null,
  };

  AdminBlockchainState copyWith({
    AdminBlockchainStatus? status,
    AdminBlockchainOverview? Function()? overview,
    Failure? Function()? failure,
    AdminBlockchainFilter? filter,
    AdminBlockchainHealthStatus? healthStatus,
    AdminBlockchainHealth? Function()? health,
    Failure? Function()? healthFailure,
  }) {
    return AdminBlockchainState(
      status: status ?? this.status,
      overview: overview == null ? this.overview : overview(),
      failure: failure == null ? this.failure : failure(),
      filter: filter ?? this.filter,
      healthStatus: healthStatus ?? this.healthStatus,
      health: health == null ? this.health : health(),
      healthFailure: healthFailure == null
          ? this.healthFailure
          : healthFailure(),
    );
  }
}
