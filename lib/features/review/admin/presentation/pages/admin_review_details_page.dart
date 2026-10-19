import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_popup.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_reject_reason_form.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/admin_review_routes.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/review/admin/domain/entities/admin_deed_details.dart';
import 'package:watad/features/review/admin/domain/entities/admin_license_details.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_target.dart';
import 'package:watad/features/review/admin/presentation/bloc/admin_review_details_bloc.dart';
import 'package:watad/features/review/admin/presentation/widgets/admin_deed_details_view.dart';
import 'package:watad/features/review/admin/presentation/widgets/admin_license_details_view.dart';
import 'package:watad/features/review/admin/presentation/widgets/admin_review_details_skeleton.dart';
import 'package:watad/features/review/admin/presentation/widgets/admin_review_requester_view.dart';

/// «تفاصيل الطلب»: everything the admin checks before deciding: who asked,
/// their business or project, and the files. «اعتماد» and «رفض» are at the
/// bottom; after a decision the page closes with `true`.
class AdminReviewDetailsPage extends StatelessWidget {
  const AdminReviewDetailsPage({required this.target, super.key});

  final AdminReviewTarget target;

  /// The rejection reasons, in order (GRA-30). Only the last one, «أخرى»,
  /// asks the admin to write the reason.
  static const _reasonKeys = [
    'review.reason_unclear',
    'review.reason_expired',
    'review.reason_mismatch',
    'review.reason_wrong_document',
    'review.reason_other',
  ];
  static final _otherReasonIndex = _reasonKeys.length - 1;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminReviewDetailsBloc, AdminReviewDetailsState>(
      listenWhen: (previous, current) =>
          (current.message != null && previous.message != current.message) ||
          previous.decision != current.decision,
      listener: (context, state) {
        final message = state.message;
        if (message != null) {
          if (message.isError) {
            context.showErrorSnackBar(context.tr(message.key));
          } else {
            context.showSuccessSnackBar(context.tr(message.key));
          }
        }
        if (state.decision == AdminReviewDecisionStatus.done) {
          _close(context, decided: true);
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppTopBar(
          title: context.tr('review.details_title'),
          onBack: () => _close(context, decided: false),
        ),
        // Loading, the request and errors fade into each other.
        body: AnimatedSwitcher(
          duration: AppMotion.enter,
          reverseDuration: AppMotion.exit,
          switchInCurve: AppMotion.enterCurve,
          switchOutCurve: AppMotion.exitCurve,
          child: KeyedSubtree(
            key: ValueKey(state.status),
            child: _body(context, state),
          ),
        ),
        bottomNavigationBar: state.details == null
            ? null
            : AppActionBar(
                primary: AppButton(
                  key: const Key('review_approve_button'),
                  label: context.tr('review.approve'),
                  variant: AppButtonVariant.dark,
                  isLoading: state.isSending,
                  onPressed: state.isSending
                      ? null
                      : () => context.read<AdminReviewDetailsBloc>().add(
                          const AdminReviewDetailsApproved(),
                        ),
                ),
                secondary: AppButton(
                  key: const Key('review_reject_button'),
                  label: context.tr('review.reject'),
                  variant: AppButtonVariant.secondary,
                  onPressed: state.isSending
                      ? null
                      : () => _showRejectForm(
                          context,
                          context.read<AdminReviewDetailsBloc>(),
                        ),
                ),
              ),
      ),
    );
  }

  /// Back to the queue: popped with [decided] when the queue opened this
  /// page, or the queue itself when the page was opened from a link.
  void _close(BuildContext context, {required bool decided}) {
    if (context.canPop()) {
      context.pop(decided);
    } else {
      context.goNamed(AdminReviewRoutes.reviewName);
    }
  }

  Widget _body(BuildContext context, AdminReviewDetailsState state) {
    final details = state.details;
    if (state.status == AdminReviewDetailsStatus.failure || details == null) {
      if (state.status == AdminReviewDetailsStatus.failure) {
        return AppErrorView(
          message: context.tr(state.failure!.messageKey),
          onRetry: () => context.read<AdminReviewDetailsBloc>().add(
            AdminReviewDetailsFetched(target),
          ),
        );
      }
      return const AdminReviewDetailsSkeleton();
    }
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        AdminReviewRequesterView(details: details, now: DateTime.now()),
        const SizedBox(height: AppSpacing.lg),
        switch (details) {
          AdminLicenseDetails() => AdminLicenseDetailsView(details: details),
          AdminDeedDetails() => AdminDeedDetailsView(details: details),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }

  void _showRejectForm(BuildContext context, AdminReviewDetailsBloc bloc) {
    final reasons = [for (final key in _reasonKeys) context.tr(key)];
    AppPopup.sheet<void>(
      context,
      // Scrolls when the reasons and the keyboard don't fit.
      builder: (sheetContext) => SingleChildScrollView(
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.md,
          end: AppSpacing.md,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.md,
        ),
        child: AppRejectReasonForm(
          reasons: reasons,
          otherReasonIndex: _otherReasonIndex,
          onSubmit: (reasonIndex, details) {
            bloc.add(
              AdminReviewDetailsRejected(
                reason: reasonIndex == _otherReasonIndex
                    ? null
                    : reasons[reasonIndex],
                details: details,
              ),
            );
            Navigator.of(sheetContext).pop();
          },
        ),
      ),
    );
  }
}
