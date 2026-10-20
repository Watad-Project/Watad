import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_kind.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_request.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_target.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_get_pending_requests_use_case.dart';

part 'admin_review_event.dart';
part 'admin_review_state.dart';

/// The admin's verification queue: pending licenses and deeds, oldest
/// first. The decisions are taken on each request's details.
class AdminReviewBloc extends Bloc<AdminReviewEvent, AdminReviewState> {
  AdminReviewBloc(this._getPendingRequests) : super(const AdminReviewState()) {
    on<AdminReviewFetched>(_onFetched);
    on<AdminReviewFilterChanged>(_onFilterChanged);
    on<AdminReviewDecided>(_onDecided);
  }

  final AdminGetPendingRequestsUseCase _getPendingRequests;

  Future<void> _onFetched(
    AdminReviewFetched event,
    Emitter<AdminReviewState> emit,
  ) async {
    emit(state.copyWith(status: AdminReviewStatus.loading));
    final result = await _getPendingRequests(const NoParams());
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: AdminReviewStatus.success,
            requests: data,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: AdminReviewStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  void _onFilterChanged(
    AdminReviewFilterChanged event,
    Emitter<AdminReviewState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
  }

  /// A request was approved or rejected on its details: it leaves the list.
  void _onDecided(AdminReviewDecided event, Emitter<AdminReviewState> emit) {
    emit(
      state.copyWith(
        requests: [
          for (final request in state.requests)
            if (request.target != event.target) request,
        ],
      ),
    );
  }
}
