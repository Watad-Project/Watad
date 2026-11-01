import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/inputs/app_switch.dart';
import 'package:watad/core/enums/notification_group.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_overview.dart';
import 'package:watad/features/settings/shared/presentation/widgets/settings_section.dart';

/// «الإشعارات»: one switch per group, the account row that's always on,
/// and what muting does.
class SettingsNotificationsSection extends StatelessWidget {
  const SettingsNotificationsSection({
    required this.overview,
    required this.onChanged,
    super.key,
  });

  final SettingsOverview overview;
  final void Function(NotificationGroup group, bool enabled) onChanged;

  static String labelKey(NotificationGroup group) => switch (group) {
    NotificationGroup.messages => 'settings.notify_messages',
    NotificationGroup.projects => 'settings.notify_projects',
    NotificationGroup.tasks => 'settings.notify_tasks',
    NotificationGroup.marketplace => 'settings.notify_marketplace',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSection(
          title: context.tr('settings.notifications'),
          rows: [
            for (final group in NotificationGroup.values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: AppSwitch(
                  key: Key('settings_notify_${group.value}'),
                  label: context.tr(labelKey(group)),
                  value: overview.isOn(group),
                  onChanged: (enabled) => onChanged(group, enabled),
                ),
              ),
            // Verification, the bank details reminder, suspension: always.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: AppSwitch(
                key: const Key('settings_notify_account'),
                label: context.tr('settings.notify_account'),
                value: true,
                onChanged: null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.tr('settings.notify_note'),
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
