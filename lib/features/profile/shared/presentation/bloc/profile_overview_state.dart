part of 'profile_overview_bloc.dart';

enum ProfileOverviewStatus { initial, loading, success, failure }

final class ProfileOverviewState {
  const ProfileOverviewState({
    this.status = ProfileOverviewStatus.initial,
    this.overview,
    this.failure,
  });

  final ProfileOverviewStatus status;

  /// The last overview the server gave. It stays while a new one loads,
  /// and when reloading fails.
  final ProfileOverview? overview;

  /// Why the last load failed.
  final Failure? failure;
}
