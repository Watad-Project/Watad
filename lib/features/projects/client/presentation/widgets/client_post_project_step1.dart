import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/inputs/app_dropdown.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_type.dart';

/// Step 1 of the post-project flow: choosing the project type.
class ClientPostProjectStep1 extends StatelessWidget {
  const ClientPostProjectStep1({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  final ClientProjectType? selectedType;
  final ValueChanged<ClientProjectType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr('projects.client.choose_type_title'),
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('projects.client.choose_type_subtitle'),
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppDropdown<ClientProjectType>(
            label: context.tr('projects.client.project_type_label'),
            hint: context.tr('projects.client.project_type_placeholder'),
            value: selectedType,
            options: [
              AppDropdownOption<ClientProjectType>(
                value: ClientProjectType.newHouse,
                title: context.tr(ClientProjectType.newHouse.titleKey),
                subtitle: context.tr(ClientProjectType.newHouse.hintKey),
                subtitleTone: AppTone.attention,
              ),
              AppDropdownOption<ClientProjectType>(
                value: ClientProjectType.renovation,
                title: context.tr(ClientProjectType.renovation.titleKey),
                subtitle: context.tr(ClientProjectType.renovation.hintKey),
                subtitleTone: AppTone.attention,
              ),
              AppDropdownOption<ClientProjectType>(
                value: ClientProjectType.repairs,
                title: context.tr(ClientProjectType.repairs.titleKey),
                subtitle: context.tr(ClientProjectType.repairs.hintKey),
                subtitleTone: AppTone.success,
              ),
            ],
            onChanged: onTypeChanged,
          ),
        ],
      ),
    );
  }
}
