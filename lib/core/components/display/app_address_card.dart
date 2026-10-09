import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_image_placeholder.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// A saved address with its name, an optional "default" badge, the address
/// line, and two actions at the bottom: edit on the map, and delete.
class AppAddressCard extends StatelessWidget {
  const AppAddressCard({
    super.key,
    required this.title,
    required this.address,
    required this.editLabel,
    required this.onEdit,
    required this.deleteLabel,
    required this.onDelete,
    this.defaultLabel,
  });

  /// E.g. "Home".
  final String title;
  final String address;
  final String editLabel;
  final VoidCallback? onEdit;
  final String deleteLabel;
  final VoidCallback? onDelete;

  /// The translated word for "default". Shown only on the default address.
  final String? defaultLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _MapTile(),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(title, style: AppTextStyles.label),
                          ),
                          if (defaultLabel != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            AppStatusBadge(label: defaultLabel!),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(address, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Action(
                    label: editLabel,
                    color: AppColors.ink,
                    onTap: onEdit,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _Action(
                    label: deleteLabel,
                    color: AppColors.error,
                    onTap: onDelete,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapTile extends StatelessWidget {
  const _MapTile();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.sm)),
      child: SizedBox.square(
        dimension: 44,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const AppImagePlaceholder(),
            Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(fontSize: 14, color: color),
          ),
        ),
      ),
    );
  }
}
