import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_rejection.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_request.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_approve_request_use_case.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_get_pending_requests_use_case.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_reject_request_use_case.dart';

part 'admin_review_event.dart';
part 'admin_review_state.dart';

/// The admin's verification queue: pending licenses, oldest first, and the
/// decisions on them.
class AdminReviewBloc extends Bloc<AdminReviewEvent, AdminReviewState> {
  AdminReviewBloc(this._getPendingRequests, this._approve, this._reject)
    : super(const AdminReviewState()) {
    on<AdminReviewFetched>(_onFetched);
    on<AdminReviewFilterChanged>(_onFilterChanged);
    on<AdminReviewApproved>(_onApproved);
    on<AdminReviewRejected>(_onRejected);
  }

  final AdminGetPendingRequestsUseCase _getPendingRequests;
  final AdminApproveRequestUseCase _approve;
  final AdminRejectRequestUseCase _reject;

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

  Future<void> _onApproved(
    AdminReviewApproved event,
    Emitter<AdminReviewState> emit,
  ) async {
    await _decide(
      emit,
      businessId: event.businessId,
      decision: () => _approve(event.businessId),
      successKey: 'review.approved',
    );
  }

  Future<void> _onRejected(
    AdminReviewRejected event,
    Emitter<AdminReviewState> emit,
  ) async {
    await _decide(
      emit,
      businessId: event.rejection.businessId,
      decision: () => _reject(event.rejection),
      successKey: 'review.rejected',
    );
  }

  /// Runs one decision. On success the request leaves the list.
  Future<void> _decide(
    Emitter<AdminReviewState> emit, {
    required String businessId,
    required Future<Result<void>> Function() decision,
    required String successKey,
  }) async {
    if (state.busyBusinessId != null) return;
    emit(state.copyWith(busyBusinessId: () => businessId));
    final result = await decision();
    switch (result) {
      case Success():
        emit(
          state.copyWith(
            requests: [
              for (final r in state.requests)
                if (r.businessId != businessId) r,
            ],
            busyBusinessId: () => null,
            message: () => AdminReviewMessage(successKey, isError: false),
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            busyBusinessId: () => null,
            message: () =>
                AdminReviewMessage(failure.messageKey, isError: true),
          ),
        );
    }
  }
}
