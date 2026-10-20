import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/router/routes/admin_review_routes.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_request.dart';
import 'package:watad/features/review/admin/presentation/bloc/admin_review_bloc.dart';
import 'package:watad/features/review/admin/presentation/widgets/admin_review_request_card.dart';
import 'package:watad/features/review/admin/presentation/widgets/admin_review_skeleton.dart';

/// «طلبات التوثيق»: the licenses and deeds waiting for an admin, oldest
/// first, in two columns. «التفاصيل» on a card opens the request, where the
/// admin decides.
class AdminReviewPage extends StatelessWidget {
  const AdminReviewPage({super.key, this.bell});

  /// The notifications bell, lent by that feature (AppSlots.notificationsBell).
  final Widget? bell;

  static const int _columns = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: context.tr('review.title'), actions: [?bell]),
      body: BlocBuilder<AdminReviewBloc, AdminReviewState>(
        // Loading, the grid and errors fade into each other.
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
    final visible = state.visible;
    return RefreshIndicator(
      key: const ValueKey('content'),
      onRefresh: () async => bloc.add(const AdminReviewFetched()),
      child: ListView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          AppFilterChips(
            labels: [
              '${context.tr('review.filter_all')} '
                  '${context.formatNumber(state.allCount)}',
              '${context.tr('review.filter_license')} '
                  '${context.formatNumber(state.licenseCount)}',
              '${context.tr('review.filter_deed')} '
                  '${context.formatNumber(state.deedCount)}',
            ],
            selectedIndex: state.filter.index,
            onSelected: (index) => bloc.add(
              AdminReviewFilterChanged(AdminReviewFilter.values[index]),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (visible.isEmpty)
            AppEmptyView(message: context.tr('review.empty'))
          else
            // Rows of two cards; each row is as tall as its taller card, so
            // large text grows the row instead of overflowing.
            for (var i = 0; i < visible.length; i += _columns) ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = i; j < i + _columns; j++) ...[
                      if (j > i) const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: j < visible.length
                            ? AdminReviewRequestCard(
                                request: visible[j],
                                now: now,
                                onDetails: () =>
                                    _openDetails(context, bloc, visible[j]),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }

  /// Opens the request; when the admin decided there, it leaves the grid.
  Future<void> _openDetails(
    BuildContext context,
    AdminReviewBloc bloc,
    AdminReviewRequest request,
  ) async {
    final decided = await context.pushNamed<bool>(
      AdminReviewRoutes.reviewDetailsName,
      pathParameters: {'kind': request.kind.name, 'id': request.id},
    );
    if (decided ?? false) bloc.add(AdminReviewDecided(request.target));
  }
}
