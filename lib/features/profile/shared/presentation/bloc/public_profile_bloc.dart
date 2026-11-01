import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_reviews_query.dart';
import 'package:watad/features/profile/shared/domain/entities/public_profile_overview.dart';
import 'package:watad/features/profile/shared/domain/usecases/get_profile_reviews_use_case.dart';
import 'package:watad/features/profile/shared/domain/usecases/get_public_profile_use_case.dart';

part 'public_profile_event.dart';
part 'public_profile_state.dart';

/// The public profile (GRA-58): a user, their items on the market and the
/// reviews about them, page by page.
class PublicProfileBloc extends Bloc<PublicProfileEvent, PublicProfileState> {
  PublicProfileBloc(this._getProfile, this._getReviews)
    : super(const PublicProfileState()) {
    on<PublicProfileFetched>(_onFetched);
    on<PublicProfileMoreReviewsRequested>(_onMoreReviews);
  }

  final GetPublicProfileUseCase _getProfile;
  final GetProfileReviewsUseCase _getReviews;

  Future<void> _onFetched(
    PublicProfileFetched event,
    Emitter<PublicProfileState> emit,
  ) async {
    // The profile stays on screen while it reloads.
    emit(
      PublicProfileState(
        status: PublicProfileStatus.loading,
        userId: event.userId,
        overview: state.userId == event.userId ? state.overview : null,
      ),
    );
    final result = await _getProfile(event.userId);
    emit(switch (result) {
      Success(:final data) => PublicProfileState(
        status: PublicProfileStatus.success,
        userId: event.userId,
        overview: data,
      ),
      Failed(:final failure) => PublicProfileState(
        status: PublicProfileStatus.failure,
        userId: event.userId,
        overview: state.overview,
        failure: failure,
      ),
    });
  }

  Future<void> _onMoreReviews(
    PublicProfileMoreReviewsRequested event,
    Emitter<PublicProfileState> emit,
  ) async {
    final overview = state.overview;
    final userId = state.userId;
    if (overview == null ||
        userId == null ||
        !overview.hasMoreReviews ||
        state.isLoadingMore) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true, moreFailure: () => null));
    final result = await _getReviews(
      ProfileReviewsQuery(userId: userId, offset: overview.reviews.length),
    );
    emit(switch (result) {
      Success(data: final more) => state.copyWith(
        overview: overview.withMoreReviews(
          more,
          hasMore: more.length == ProfileReviewsQuery.pageSize,
        ),
        isLoadingMore: false,
      ),
      Failed(:final failure) => state.copyWith(
        isLoadingMore: false,
        moreFailure: () => failure,
      ),
    });
  }
}
