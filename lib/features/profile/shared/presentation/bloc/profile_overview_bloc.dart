import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_overview.dart';
import 'package:watad/features/profile/shared/domain/usecases/get_profile_overview_use_case.dart';

part 'profile_overview_event.dart';
part 'profile_overview_state.dart';

/// The account tabs «حسابي» and «منشأتي» (GRA-59): the signed-in user's
/// profile and rating.
class ProfileOverviewBloc
    extends Bloc<ProfileOverviewEvent, ProfileOverviewState> {
  ProfileOverviewBloc(this._getOverview) : super(const ProfileOverviewState()) {
    on<ProfileOverviewFetched>(_onFetched);
  }

  final GetProfileOverviewUseCase _getOverview;

  Future<void> _onFetched(
    ProfileOverviewFetched event,
    Emitter<ProfileOverviewState> emit,
  ) async {
    // The profile stays on screen while it reloads.
    if (state.overview == null) {
      emit(const ProfileOverviewState(status: ProfileOverviewStatus.loading));
    }
    final result = await _getOverview(const NoParams());
    emit(switch (result) {
      Success(:final data) => ProfileOverviewState(
        status: ProfileOverviewStatus.success,
        overview: data,
      ),
      Failed(:final failure) => ProfileOverviewState(
        status: ProfileOverviewStatus.failure,
        overview: state.overview,
        failure: failure,
      ),
    });
  }
}
