import 'package:flutter/material.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// The conversation while it loads: bubbles on both sides, shimmering.
class ChatSkeleton extends StatelessWidget {
  const ChatSkeleton({super.key});

  static const List<(bool, double)> _bubbles = [
    (false, 180),
    (true, 220),
    (false, 140),
    (true, 160),
  ];

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            for (final (mine, width) in _bubbles) ...[
              Align(
                alignment: mine
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: AppSkeletonBox(
                  height: 44,
                  width: width,
                  radius: AppRadius.lg,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}
