import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_details.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_kind.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_rejection.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_target.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_approve_request_use_case.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_get_request_details_use_case.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_reject_request_use_case.dart';

part 'admin_review_details_event.dart';
part 'admin_review_details_state.dart';

/// One request: its requester and files, and the admin's decision on it.
class AdminReviewDetailsBloc
    extends Bloc<AdminReviewDetailsEvent, AdminReviewDetailsState> {
  AdminReviewDetailsBloc(this._getDetails, this._approve, this._reject)
    : super(const AdminReviewDetailsState()) {
    on<AdminReviewDetailsFetched>(_onFetched);
    on<AdminReviewDetailsApproved>(_onApproved);
    on<AdminReviewDetailsRejected>(_onRejected);
  }

  final AdminGetRequestDetailsUseCase _getDetails;
  final AdminApproveRequestUseCase _approve;
  final AdminRejectRequestUseCase _reject;

  Future<void> _onFetched(
    AdminReviewDetailsFetched event,
    Emitter<AdminReviewDetailsState> emit,
  ) async {
    emit(state.copyWith(status: AdminReviewDetailsStatus.loading));
    final result = await _getDetails(event.target);
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: AdminReviewDetailsStatus.success,
            details: () => data,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: AdminReviewDetailsStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  Future<void> _onApproved(
    AdminReviewDetailsApproved event,
    Emitter<AdminReviewDetailsState> emit,
  ) async {
    final target = state.details?.target;
    if (target == null) return;
    await _decide(
      emit,
      decision: () => _approve(target),
      successKey: switch (target.kind) {
        AdminReviewKind.license => 'review.approved',
        AdminReviewKind.deed => 'review.deed_approved',
      },
    );
  }

  Future<void> _onRejected(
    AdminReviewDetailsRejected event,
    Emitter<AdminReviewDetailsState> emit,
  ) async {
    final target = state.details?.target;
    if (target == null) return;
    await _decide(
      emit,
      decision: () => _reject(
        AdminReviewRejection(
          target: target,
          reason: event.reason,
          details: event.details,
        ),
      ),
      successKey: switch (target.kind) {
        AdminReviewKind.license => 'review.rejected',
        AdminReviewKind.deed => 'review.deed_rejected',
      },
    );
  }

  /// Runs one decision at a time. On success the page closes.
  Future<void> _decide(
    Emitter<AdminReviewDetailsState> emit, {
    required Future<Result<void>> Function() decision,
    required String successKey,
  }) async {
    if (state.decision != AdminReviewDecisionStatus.idle) return;
    emit(state.copyWith(decision: AdminReviewDecisionStatus.sending));
    final result = await decision();
    switch (result) {
      case Success():
        emit(
          state.copyWith(
            decision: AdminReviewDecisionStatus.done,
            message: () => AdminReviewMessage(successKey, isError: false),
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            decision: AdminReviewDecisionStatus.idle,
            message: () =>
                AdminReviewMessage(failure.messageKey, isError: true),
          ),
        );
    }
  }
}
