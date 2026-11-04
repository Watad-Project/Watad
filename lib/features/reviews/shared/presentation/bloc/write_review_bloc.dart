import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_draft.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_input.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_subject.dart';
import 'package:watad/features/reviews/shared/domain/usecases/get_review_draft_use_case.dart';
import 'package:watad/features/reviews/shared/domain/usecases/save_review_use_case.dart';

part 'write_review_event.dart';
part 'write_review_state.dart';

/// The review sheet (GRA-61): whom I'm rating and my earlier review, then
/// saving it.
class WriteReviewBloc extends Bloc<WriteReviewEvent, WriteReviewState> {
  WriteReviewBloc(this._getDraft, this._save)
    : super(const WriteReviewState()) {
    on<WriteReviewStarted>(_onStarted);
    on<WriteReviewSubmitted>(_onSubmitted);
  }

  final GetReviewDraftUseCase _getDraft;
  final SaveReviewUseCase _save;

  Future<void> _onStarted(
    WriteReviewStarted event,
    Emitter<WriteReviewState> emit,
  ) async {
    emit(
      WriteReviewState(
        status: WriteReviewStatus.loading,
        subject: event.subject,
      ),
    );
    final result = await _getDraft(event.subject);
    emit(switch (result) {
      Success(:final data) => WriteReviewState(
        status: WriteReviewStatus.ready,
        subject: event.subject,
        draft: data,
      ),
      Failed(:final failure) => WriteReviewState(
        status: WriteReviewStatus.failure,
        subject: event.subject,
        failure: failure,
      ),
    });
  }

  Future<void> _onSubmitted(
    WriteReviewSubmitted event,
    Emitter<WriteReviewState> emit,
  ) async {
    final subject = state.subject;
    final draft = state.draft;
    if (subject == null || draft == null || state.isSaving) return;
    emit(state.copyWith(isSaving: true, saveFailure: () => null));
    final result = await _save(
      ReviewInput(
        subject: subject,
        rating: event.rating,
        comment: event.comment,
        existingId: draft.existing?.id,
      ),
    );
    emit(switch (result) {
      Success() => state.copyWith(
        status: WriteReviewStatus.saved,
        isSaving: false,
      ),
      Failed(:final failure) => state.copyWith(
        isSaving: false,
        saveFailure: () => failure,
      ),
    });
  }
}
