import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/location/shared/domain/entities/location_suggestion.dart';

/// The places matching the map's search, under its field: a tap moves the
/// map there. Shows nothing until there is something to show.
class LocationSearchSuggestions extends StatelessWidget {
  const LocationSearchSuggestions({
    required this.suggestions,
    required this.isSearching,
    required this.onSelected,
    this.message,
    super.key,
  });

  final List<LocationSuggestion> suggestions;

  /// A thin bar runs along the top while a search is on its way.
  final bool isSearching;

  /// Shown instead of the list: no place has that name, or the search
  /// failed.
  final String? message;
  final ValueChanged<LocationSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    if (suggestions.isEmpty && !isSearching && message == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
      child: Material(
        color: AppColors.surface,
        elevation: 3,
        shadowColor: Colors.black26,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isSearching)
              const LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.primary,
                backgroundColor: AppColors.border,
              ),
            if (message != null)
              Padding(
                padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                child: Text(
                  message,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) => _SuggestionRow(
                    suggestion: suggestions[index],
                    onTap: () => onSelected(suggestions[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.suggestion, required this.onTap});

  final LocationSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = suggestion.subtitle;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.place_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.title,
                      style: AppTextStyles.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
