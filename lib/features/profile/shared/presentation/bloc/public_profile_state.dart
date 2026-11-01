part of 'public_profile_bloc.dart';

enum PublicProfileStatus { initial, loading, success, failure }

final class PublicProfileState {
  const PublicProfileState({
    this.status = PublicProfileStatus.initial,
    this.userId,
    this.overview,
    this.failure,
    this.isLoadingMore = false,
    this.moreFailure,
  });

  final PublicProfileStatus status;

  /// From the route, so a retry knows whom to load.
  final String? userId;

  /// The last profile the server gave. It stays while it reloads, and when
  /// reloading fails.
  final PublicProfileOverview? overview;

  /// Why the last load failed.
  final Failure? failure;

  /// The next page of reviews is loading.
  final bool isLoadingMore;

  /// Why the last page of reviews couldn't load.
  final Failure? moreFailure;

  PublicProfileState copyWith({
    PublicProfileOverview? overview,
    bool? isLoadingMore,
    Failure? Function()? moreFailure,
  }) {
    return PublicProfileState(
      status: status,
      userId: userId,
      overview: overview ?? this.overview,
      failure: failure,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      moreFailure: moreFailure == null ? this.moreFailure : moreFailure(),
    );
  }
}
