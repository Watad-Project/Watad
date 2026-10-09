import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// Where an [AppTimelineItem] stands.
enum AppTimelineState {
  /// A green check.
  done,

  /// An orange dot.
  current,

  /// An empty ring.
  upcoming,
}

/// One entry of an [AppTimeline], e.g. a project task.
class AppTimelineItem {
  const AppTimelineItem({
    required this.title,
    required this.state,
    this.subtitle,
    this.trailing,
    this.tag,
  });

  final String title;
  final AppTimelineState state;

  /// E.g. "Done on 24 February".
  final String? subtitle;

  /// A short value at the end of the title line, e.g. the task amount.
  final String? trailing;

  /// Shown under the text, usually an `AppIconTag`.
  final Widget? tag;
}

/// A vertical list of steps joined by a line, e.g. the tasks of a project
/// (client and contractor views).
class AppTimeline extends StatelessWidget {
  const AppTimeline({super.key, required this.items});

  final List<AppTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++)
          _Entry(item: items[i], isLast: i == items.length - 1),
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.item, required this.isLast});

  final AppTimelineItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                _Marker(state: item.state),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.track,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(item.title, style: AppTextStyles.h2),
                      ),
                      if (item.trailing != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            item.trailing!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.subtitle != null)
                    Text(item.subtitle!, style: AppTextStyles.caption),
                  if (item.tag != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    item.tag!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.state});

  final AppTimelineState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (state) {
          AppTimelineState.done => AppColors.success,
          AppTimelineState.current => AppColors.primary,
          AppTimelineState.upcoming => AppColors.surface,
        },
        border: state == AppTimelineState.upcoming
            ? Border.all(color: AppColors.controlBorder, width: 2)
            : null,
      ),
      child: switch (state) {
        AppTimelineState.done => const Icon(
          Icons.check,
          size: 16,
          color: AppColors.white,
        ),
        AppTimelineState.current => Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
        AppTimelineState.upcoming => null,
      },
    );
  }
}
