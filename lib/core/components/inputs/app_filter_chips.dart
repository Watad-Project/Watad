import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// A scrollable row of round filter chips with one selected, e.g.
/// "All · Steel · Concrete · Surplus" in the market.
class AppFilterChips extends StatelessWidget {
  const AppFilterChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.isWrapped = false,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool isWrapped;

  @override
  Widget build(BuildContext context) {
    if (isWrapped) {
      return Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (var i = 0; i < labels.length; i++)
            _Chip(
              label: labels[i],
              selected: i == selectedIndex,
              onTap: () => onSelected(i),
            ),
        ],
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            _Chip(
              label: labels[i],
              selected: i == selectedIndex,
              onTap: () => onSelected(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The chip is 38 high, inside a 48 high tap target.
    return Semantics(
      selected: selected,
      button: true,
      child: SizedBox(
        height: AppSizes.minTapTarget,
        // Centered in the tap target's height, as wide as its label: in a
        // Wrap a plain Center would stretch the chip to the whole line.
        child: Align(
          widthFactor: 1,
          child: Material(
            color: selected ? AppColors.ink : AppColors.surface,
            shape: StadiumBorder(
              side: selected
                  ? BorderSide.none
                  : const BorderSide(color: AppColors.borderStrong),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    label,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 14,
                      color: selected ? AppColors.white : AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
