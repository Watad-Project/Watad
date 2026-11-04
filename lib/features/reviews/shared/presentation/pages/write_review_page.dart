import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_draft.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_input.dart';
import 'package:watad/features/reviews/shared/presentation/bloc/write_review_bloc.dart';
import 'package:watad/features/reviews/shared/presentation/widgets/review_stars.dart';

/// The review sheet (GRA-61): 1 to 5 stars and an optional comment about
/// the other party of a completed project or a delivered order. My earlier
/// review opens for editing. Closes with `true` once saved.
class WriteReviewPage extends StatelessWidget {
  const WriteReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WriteReviewBloc, WriteReviewState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.saveFailure != current.saveFailure,
      listener: (context, state) {
        if (state.status == WriteReviewStatus.saved) {
          context.showSuccessSnackBar(context.tr('reviews.saved'));
          if (context.canPop()) context.pop(true);
          return;
        }
        if (state.saveFailure case final failure?) {
          context.showErrorSnackBar(context.tr(failure.messageKey));
        }
      },
      builder: (context, state) {
        final bloc = context.read<WriteReviewBloc>();
        return Material(
          color: AppColors.surface,
          child: SafeArea(
            top: false,
            child: switch ((state.status, state.draft)) {
              (_, final draft?) => _ReviewForm(
                key: ValueKey(draft.existing?.id),
                draft: draft,
                isProject: state.subject?.isProject ?? false,
                isSaving: state.isSaving,
                onSubmit: (rating, comment) => bloc.add(
                  WriteReviewSubmitted(rating: rating, comment: comment),
                ),
              ),
              (WriteReviewStatus.failure, _) => AppErrorView(
                message: context.tr(state.failure!.messageKey),
                onRetry: () {
                  if (state.subject case final subject?) {
                    bloc.add(WriteReviewStarted(subject));
                  }
                },
              ),
              _ => const Padding(
                padding: EdgeInsetsDirectional.all(AppSpacing.xl),
                child: AppLoadingIndicator(),
              ),
            },
          ),
        );
      },
    );
  }
}

class _ReviewForm extends StatefulWidget {
  const _ReviewForm({
    required this.draft,
    required this.isProject,
    required this.isSaving,
    required this.onSubmit,
    super.key,
  });

  final ReviewDraft draft;
  final bool isProject;
  final bool isSaving;
  final void Function(int rating, String comment) onSubmit;

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _comment = TextEditingController(
    text: widget.draft.existing?.comment ?? '',
  );
  late int _rating = widget.draft.existing?.rating ?? 0;
  bool _showRatingError = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    setState(() => _showRatingError = _rating < ReviewInput.minRating);
    if (!isValid || _showRatingError) return;
    widget.onSubmit(_rating, _comment.text);
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final name = draft.targetName.isEmpty
        ? context.tr('reviews.no_name')
        : draft.targetName;
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr(
                draft.existing == null ? 'reviews.title' : 'reviews.edit_title',
                args: [name],
              ),
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.tr(
                widget.isProject
                    ? 'reviews.about_project'
                    : 'reviews.about_order',
              ),
              style: AppTextStyles.body.copyWith(color: AppColors.textBody),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ReviewStars(
              rating: _rating,
              onChanged: (rating) => setState(() {
                _rating = rating;
                _showRatingError = false;
              }),
            ),
            if (_showRatingError)
              Text(
                context.tr('reviews.error_rating'),
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const Key('review_comment'),
              label: context.tr('reviews.comment_label'),
              hint: context.tr('reviews.comment_hint'),
              controller: _comment,
              keyboardType: TextInputType.multiline,
              minLines: 3,
              maxLines: 6,
              validator: (value) =>
                  (value ?? '').trim().length > ReviewInput.maxCommentLength
                  ? context.tr('reviews.error_comment_long')
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const Key('review_save'),
              label: context.tr('reviews.save'),
              isLoading: widget.isSaving,
              onPressed: widget.isSaving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
