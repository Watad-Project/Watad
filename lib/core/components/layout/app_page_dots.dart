import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// One dot per page under swipeable pages (onboarding); the current page is
/// a wider orange pill. The dots follow the reading direction, so the first
/// page is on the right in Arabic.
class AppPageDots extends StatelessWidget {
  const AppPageDots({
    super.key,
    required this.count,
    required this.currentIndex,
    this.semanticLabel,
  });

  static const double _dotSize = 8;
  static const double _pillWidth = 24;

  final int count;

  /// The current page, counted from 0.
  final int currentIndex;

  /// What screen readers say, e.g. "Page 2 of 3". Without it the dots are
  /// treated as decoration.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == currentIndex ? _pillWidth : _dotSize,
              height: _dotSize,
              decoration: BoxDecoration(
                color: i == currentIndex ? AppColors.primary : AppColors.track,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.pill),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
