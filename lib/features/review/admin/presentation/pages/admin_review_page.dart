import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_popup.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';
import 'package:watad/core/components/inputs/app_reject_reason_form.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/admin_review_routes.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_rejection.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_request.dart';
import 'package:watad/features/review/admin/presentation/bloc/admin_review_bloc.dart';
import 'package:watad/features/review/admin/presentation/widgets/admin_review_request_card.dart';
import 'package:watad/features/review/admin/presentation/widgets/admin_review_skeleton.dart';

/// «طلبات التوثيق»: the licenses waiting for an admin, oldest first.
class AdminReviewPage extends StatelessWidget {
  const AdminReviewPage({super.key});

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
    return Scaffold(
      appBar: AppTopBar(title: context.tr('review.title')),
      body: BlocConsumer<AdminReviewBloc, AdminReviewState>(
        listenWhen: (previous, current) =>
            current.message != null && previous.message != current.message,
        listener: (context, state) {
          final message = state.message!;
          if (message.isError) {
            context.showErrorSnackBar(context.tr(message.key));
          } else {
            context.showSuccessSnackBar(context.tr(message.key));
          }
        },
        // Loading, the list and errors fade into each other.
        builder: (context, state) => AnimatedSwitcher(
          duration: AppMotion.enter,
          reverseDuration: AppMotion.exit,
          switchInCurve: AppMotion.enterCurve,
          switchOutCurve: AppMotion.exitCurve,
          child: _body(context, state),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AdminReviewState state) {
    final bloc = context.read<AdminReviewBloc>();
    if (state.requests.isEmpty) {
      if (state.status == AdminReviewStatus.failure) {
        return AppErrorView(
          message: context.tr(state.failure!.messageKey),
          onRetry: () => bloc.add(const AdminReviewFetched()),
        );
      }
      if (state.status != AdminReviewStatus.success) {
        return const AdminReviewSkeleton(key: ValueKey('loading'));
      }
    }
    final now = DateTime.now();
    return RefreshIndicator(
      key: const ValueKey('content'),
      onRefresh: () async => bloc.add(const AdminReviewFetched()),
      child: ListView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          AppFilterChips(
            labels: [
              '${context.tr('review.filter_all')} ${state.allCount}',
              '${context.tr('review.filter_license')} '
                  '${state.licenseCount}',
              '${context.tr('review.filter_deed')} 0',
            ],
            selectedIndex: state.filter.index,
            onSelected: (index) => bloc.add(
              AdminReviewFilterChanged(AdminReviewFilter.values[index]),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.visible.isEmpty)
            AppEmptyView(
              message: context.tr(
                state.filter == AdminReviewFilter.deed
                    ? 'review.deeds_soon'
                    : 'review.empty',
              ),
            )
          else
            for (final request in state.visible) ...[
              AdminReviewRequestCard(
                request: request,
                now: now,
                isBusy: state.busyBusinessId == request.businessId,
                onOpen: () => context.pushNamed(
                  AdminReviewRoutes.reviewDocumentsName,
                  pathParameters: {'businessId': request.businessId},
                ),
                onApprove: () =>
                    bloc.add(AdminReviewApproved(request.businessId)),
                onReject: () => _showRejectForm(context, bloc, request),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }

  void _showRejectForm(
    BuildContext context,
    AdminReviewBloc bloc,
    AdminReviewRequest request,
  ) {
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
              AdminReviewRejected(
                AdminReviewRejection(
                  businessId: request.businessId,
                  reason: reasonIndex == _otherReasonIndex
                      ? null
                      : reasons[reasonIndex],
                  details: details,
                ),
              ),
            );
            Navigator.of(sheetContext).pop();
          },
        ),
      ),
    );
  }
}
