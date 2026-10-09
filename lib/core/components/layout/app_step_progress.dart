import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// "Step 2 of 4" with one bar per step, the done ones in orange. Used at the
/// top of multi-step flows such as publishing a project.
class AppStepProgress extends StatelessWidget {
  const AppStepProgress({
    super.key,
    required this.current,
    required this.total,
    required this.label,
  });

  /// The current step, counted from 1.
  final int current;
  final int total;

  /// E.g. "Step 2 of 4".
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: i < current ? AppColors.primary : AppColors.track,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
