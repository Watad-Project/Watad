import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/router/routes/chat_routes.dart';
import 'package:watad/core/router/routes/profile_routes.dart';
import 'package:watad/core/router/routes/support_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/profile/shared/domain/entities/public_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/public_profile_overview.dart';
import 'package:watad/features/profile/shared/presentation/bloc/public_profile_bloc.dart';
import 'package:watad/features/profile/shared/presentation/widgets/public_profile_header.dart';
import 'package:watad/features/profile/shared/presentation/widgets/public_profile_items.dart';
import 'package:watad/features/profile/shared/presentation/widgets/public_profile_review_tile.dart';

/// A user's public profile (GRA-58): what a client looks at before
/// accepting an offer, and what anyone sees about a seller. The header,
/// their items on the market and the reviews about them.
class PublicProfilePage extends StatelessWidget {
  const PublicProfilePage({this.now, super.key});

  /// The clock for «آخر ظهور»; the phone's by default (tests set it).
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: context.tr('profile.public.title'),
        onBack: () => context.pop(),
      ),
      body: BlocConsumer<PublicProfileBloc, PublicProfileState>(
        listenWhen: (previous, current) =>
            current.moreFailure != null &&
            previous.moreFailure != current.moreFailure,
        listener: (context, state) => context.showErrorSnackBar(
          context.tr(state.moreFailure!.messageKey),
        ),
        // Loading, the profile and errors fade into each other.
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

  Widget _body(BuildContext context, PublicProfileState state) {
    final bloc = context.read<PublicProfileBloc>();
    void reload() {
      if (state.userId case final userId?) {
        bloc.add(PublicProfileFetched(userId));
      }
    }

    final overview = state.overview;
    if (overview == null) {
      return switch (state.failure) {
        NotFoundFailure() => AppEmptyView(
          key: const ValueKey('not_found'),
          message: context.tr('profile.public.not_found'),
          icon: Icons.person_off_outlined,
        ),
        final failure? => AppErrorView(
          key: const ValueKey('error'),
          message: context.tr(failure.messageKey),
          onRetry: reload,
        ),
        null => const AppLoadingIndicator(key: ValueKey('loading')),
      };
    }
    return RefreshIndicator(
      key: const ValueKey('profile'),
      onRefresh: () async => reload(),
      child: ListView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          PublicProfileHeader(
            profile: overview.profile,
            now: now ?? DateTime.now(),
          ),
          ..._actions(context, overview.profile),
          if (!overview.profile.isDeleted) ...[
            const SizedBox(height: AppSpacing.lg),
            AppSectionHeader(
              title: context.tr('profile.public.items'),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.sm),
            PublicProfileItems(
              items: overview.items,
              sellerName: overview.profile.displayName,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(
            title: context.tr('profile.public.reviews'),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._reviews(context, state, overview),
        ],
      ),
    );
  }

  /// «مراسلة» and «إبلاغ» for someone else, «تعديل الملف» on my own profile, and
  /// nothing for a closed account.
  List<Widget> _actions(BuildContext context, PublicProfile profile) {
    if (profile.isDeleted) return const [];
    return [
      const SizedBox(height: AppSpacing.md),
      if (profile.isMe)
        AppButton(
          key: const Key('public_profile_edit'),
          label: context.tr('profile.public.edit'),
          variant: AppButtonVariant.secondary,
          icon: Icons.edit_outlined,
          onPressed: () => context.pushNamed(ProfileRoutes.profileEditName),
        )
      else ...[
        AppButton(
          key: const Key('public_profile_message'),
          label: context.tr('profile.public.message'),
          icon: Icons.chat_bubble_outline_rounded,
          onPressed: () => context.pushNamed(
            ChatRoutes.chatStartName,
            pathParameters: {'userId': profile.id},
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          key: const Key('public_profile_report'),
          label: context.tr('profile.public.report'),
          variant: AppButtonVariant.link,
          icon: Icons.flag_outlined,
          onPressed: () => context.pushNamed(
            SupportRoutes.supportNewReportName,
            queryParameters: {'target': 'user', 'id': profile.id},
          ),
        ),
      ],
    ];
  }

  List<Widget> _reviews(
    BuildContext context,
    PublicProfileState state,
    PublicProfileOverview overview,
  ) {
    if (overview.reviews.isEmpty) {
      return [
        Text(
          context.tr('profile.no_ratings'),
          style: AppTextStyles.body.copyWith(color: AppColors.textBody),
        ),
      ];
    }
    return [
      for (final (index, review) in overview.reviews.indexed) ...[
        if (index > 0) const SizedBox(height: AppSpacing.sm),
        PublicProfileReviewTile(key: ValueKey(review.id), review: review),
      ],
      if (overview.hasMoreReviews) ...[
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          key: const Key('public_profile_more_reviews'),
          label: context.tr('profile.public.more_reviews'),
          variant: AppButtonVariant.link,
          isLoading: state.isLoadingMore,
          onPressed: state.isLoadingMore
              ? null
              : () => context.read<PublicProfileBloc>().add(
                  const PublicProfileMoreReviewsRequested(),
                ),
        ),
      ],
    ];
  }
}
