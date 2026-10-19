import 'package:flutter/material.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/home/client/presentation/widgets/client_contractor_card.dart';
import 'package:watad/features/home/client/presentation/widgets/client_contractor_card_skeleton.dart';

/// Shimmering cards, two per row, while the «الكل» grid loads.
class ClientContractorsSkeleton extends StatelessWidget {
  const ClientContractorsSkeleton({super.key});

  static const int _cards = 6;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisExtent: ClientContractorCard.height,
        ),
        itemCount: _cards,
        itemBuilder: (_, _) => const ClientContractorCardSkeleton(),
      ),
    );
  }
}
