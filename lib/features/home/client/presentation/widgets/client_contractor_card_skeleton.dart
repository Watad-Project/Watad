import 'package:flutter/widgets.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// The shape of a ClientContractorCard while contractors load. Put it in an
/// AppShimmer.
class ClientContractorCardSkeleton extends StatelessWidget {
  const ClientContractorCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
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
  }
}
