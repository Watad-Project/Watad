import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// One tab of an [AppBottomNav].
class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.badgeCount,
  });

  final IconData icon;
  final String label;

  /// Shown when the tab is selected, e.g. the filled form of [icon].
  final IconData? activeIcon;

  /// A count on the tab's icon (e.g. requests waiting for an admin). Null or
  /// 0 shows no badge; above 99 shows "99+".
  final int? badgeCount;
}

/// The bar of main tabs at the bottom of the main screens: a rounded bar
/// floating above the bottom edge, the selected tab in an orange pill. One
/// component for every role: the navigation passes the tabs of the role
/// (client: Home, My projects, Market, Chats, Account; contractor: Dashboard,
/// Work, Market, Chats, My business).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          0,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxs + 2),
            child: Row(
              children: [
                for (final (index, item) in items.indexed)
                  Expanded(
                    child: _AppBottomNavTab(
                      item: item,
                      selected: index == currentIndex,
                      onTap: () => onTap(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBottomNavTab extends StatelessWidget {
  const _AppBottomNavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    final count = item.badgeCount ?? 0;
    final badge = count > 99 ? '99+' : '$count';
    return Semantics(
      button: true,
      selected: selected,
      label: count > 0 ? '${item.label}, $badge' : item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            color: selected ? AppColors.primarySoft : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: count > 0,
                label: Text(badge),
                backgroundColor: AppColors.error,
                textStyle: AppTextStyles.labelSmall.copyWith(fontSize: 10),
                child: Icon(
                  selected ? item.activeIcon ?? item.icon : item.icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs / 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 11,
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
