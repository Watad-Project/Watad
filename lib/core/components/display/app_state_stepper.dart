import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// The states something goes through, in a row, with the reached ones in
/// orange, e.g. a task: proposed → accepted → done → approved → paid.
///
/// The caller passes the translated [labels] in order and the index of the
/// current state.
class AppStateStepper extends StatelessWidget {
  const AppStateStepper({
    super.key,
    required this.labels,
    required this.currentIndex,
  });

  final List<String> labels;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final last = labels.length - 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Semantics(
              selected: i == currentIndex,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: i == 0 ? const SizedBox() : _line),
                      _Dot(isReached: i <= currentIndex),
                      Expanded(child: i == last ? const SizedBox() : _line),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs + 2),
                  Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: i <= currentIndex
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                      fontWeight: i <= currentIndex
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static const Widget _line = SizedBox(
    height: 2,
    child: ColoredBox(color: AppColors.track),
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.isReached});

  final bool isReached;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isReached ? AppColors.primary : AppColors.surface,
        border: isReached
            ? null
            : Border.all(color: AppColors.controlBorder, width: 2),
      ),
    );
  }
}
