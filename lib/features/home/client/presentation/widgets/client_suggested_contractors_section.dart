import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_business_mini_card.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/home/client/domain/entities/client_contractor.dart';
import 'package:watad/features/home/client/presentation/bloc/client_home_bloc.dart';

/// «مقاولون مقترحون»: the five best rated verified contractors in a
/// horizontal row, two on screen at a time. «الكل» opens every contractor.
class ClientSuggestedContractorsSection extends StatelessWidget {
  const ClientSuggestedContractorsSection({
    required this.status,
    required this.contractors,
    required this.onRetry,
    required this.onViewAll,
    this.failureMessage,
    super.key,
  });

  final ClientHomeStatus status;
  final List<ClientContractor> contractors;

  /// Shown when the contractors couldn't load.
  final String? failureMessage;
  final VoidCallback onRetry;

  /// «الكل».
  final VoidCallback onViewAll;

  static const double _rowHeight = 160;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('home.suggested_contractors'),
                style: AppTextStyles.h2,
              ),
            ),
            AppButton(
              label: context.tr('home.view_all'),
              variant: AppButtonVariant.link,
              onPressed: onViewAll,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedSwitcher(
          duration: AppMotion.enter,
          reverseDuration: AppMotion.exit,
          switchInCurve: AppMotion.enterCurve,
          switchOutCurve: AppMotion.exitCurve,
          child: KeyedSubtree(key: ValueKey(status), child: _body(context)),
        ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    switch (status) {
      case ClientHomeStatus.failure:
        return AppErrorView(
          message: failureMessage ?? context.tr('errors.unknown'),
          onRetry: onRetry,
        );
      case ClientHomeStatus.success when contractors.isEmpty:
        return AppEmptyView(
          message: context.tr('home.no_contractors'),
          icon: Icons.engineering_outlined,
        );
      case ClientHomeStatus.success:
        return SizedBox(
          height: _rowHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - AppSpacing.sm) / 2;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: contractors.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) => SizedBox(
                  width: width,
                  child: _ContractorCard(contractor: contractors[index]),
                ),
              );
            },
          ),
        );
      case ClientHomeStatus.initial || ClientHomeStatus.loading:
        return const _ContractorsSkeleton(height: _rowHeight);
    }
  }
}

class _ContractorCard extends StatelessWidget {
  const _ContractorCard({required this.contractor});

  final ClientContractor contractor;

  @override
  Widget build(BuildContext context) {
    final rating = contractor.ratingAvg;
    final count = contractor.ratingCount;
    return AppBusinessMiniCard(
      name: contractor.companyName,
      isVerified: true,
      imageUrl: contractor.avatarUrl,
      ratingLabel: rating == null
          ? '–'
          : context.formatNumber(rating, decimals: 1),
      projectsLabel: count == 0
          ? context.tr('home.no_ratings')
          : context.plural(
              'home.ratings_count',
              count,
              args: [context.formatNumber(count)],
            ),
    );
  }
}

/// Two shimmering cards while the contractors load.
class _ContractorsSkeleton extends StatelessWidget {
  const _ContractorsSkeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    const card = AppCard(
      padding: EdgeInsetsDirectional.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSkeletonBox(height: 80, radius: 0),
          Padding(
            padding: EdgeInsetsDirectional.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeletonBox(height: 14, width: 100),
                SizedBox(height: AppSpacing.xs),
                AppSkeletonBox(height: 12, width: 70),
              ],
            ),
          ),
        ],
      ),
    );
    return SizedBox(
      height: height,
      child: const AppShimmer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: card),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: card),
          ],
        ),
      ),
    );
  }
}
