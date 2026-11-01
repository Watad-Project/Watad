import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_icon_tag.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/components/inputs/app_field_label.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile_business.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_specialty.dart';
import 'package:watad/features/profile/shared/presentation/widgets/profile_city_field.dart';
import 'package:watad/features/profile/shared/presentation/widgets/profile_specialty_text.dart';

/// The business part of the edit form (GRA-60): the company name, the
/// specialty (GRA-16's five choices), the city and the CR number. While the
/// business is verified, the CR number is locked (migration 86).
class ProfileBusinessFields extends StatelessWidget {
  const ProfileBusinessFields({
    required this.business,
    required this.companyNameController,
    required this.crNumberController,
    required this.onChanged,
    required this.onSpecialtyPicked,
    this.pickedSpecialty,
    this.city,
    this.onCityTap,
    this.companyNameError,
    this.crNumberError,
    this.enabled = true,
    super.key,
  });

  /// The business as the server has it.
  final MyProfileBusiness business;
  final TextEditingController companyNameController;
  final TextEditingController crNumberController;

  /// The company name or the CR number changed.
  final VoidCallback onChanged;

  /// The label of the tapped chip, or null for the specialty already saved.
  final ValueChanged<String?> onSpecialtyPicked;

  /// The picked chip's label; null shows the saved specialty.
  final String? pickedSpecialty;

  /// The city to show: the picked one, else the saved one.
  final String? city;

  /// Opens the city search; null while the form can't change.
  final VoidCallback? onCityTap;

  /// Translation keys; null when the field is fine.
  final String? companyNameError;
  final String? crNumberError;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    String? errorOf(String? key) => key == null ? null : context.tr(key);
    final labels = [
      for (final choice in ProfileSpecialty.values)
        context.tr(ProfileSpecialtyText.labelKey(choice)),
    ];
    final saved = business.specializedField;
    final savedChoice = ProfileSpecialtyText.choiceOf(context, saved);
    final picked = pickedSpecialty;
    final selectedIndex = picked == null
        ? savedChoice?.index ?? -1
        : labels.indexOf(picked);
    // A saved specialty that is none of the choices stays until one is
    // picked: say what it is.
    final showsSaved =
        selectedIndex < 0 &&
        savedChoice == null &&
        !ProfileSpecialty.isUnset(saved);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: const Key('profile_edit_company_name'),
          label: context.tr('profile.edit.company_name'),
          isRequired: true,
          controller: companyNameController,
          errorText: errorOf(companyNameError),
          textInputAction: TextInputAction.next,
          enabled: enabled,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppFieldLabel(
          label: context.tr('profile.edit.specialty'),
          isRequired: true,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppFilterChips(
          key: const Key('profile_edit_specialty'),
          labels: labels,
          selectedIndex: selectedIndex,
          isWrapped: true,
          onSelected: (index) {
            if (!enabled) return;
            final choice = ProfileSpecialty.values[index];
            onSpecialtyPicked(choice == savedChoice ? null : labels[index]);
          },
        ),
        if (showsSaved)
          Text(
            context.tr('profile.edit.specialty_current', args: [saved.trim()]),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        ProfileCityField(city: city, onTap: onCityTap),
        const SizedBox(height: AppSpacing.md),
        if (business.verificationStatus == VerificationStatus.verified) ...[
          AppKeyValueList(
            rows: [
              AppKeyValueRow(
                label: context.tr('profile.edit.cr_number'),
                value: business.crNumber,
                isMonospace: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppIconTag(
              key: const Key('profile_edit_cr_number_locked'),
              label: context.tr('profile.edit.cr_number_locked'),
              icon: Icons.lock_outline,
              tone: AppTone.neutral,
            ),
          ),
        ] else
          AppTextField(
            key: const Key('profile_edit_cr_number'),
            label: context.tr('profile.edit.cr_number'),
            isRequired: true,
            controller: crNumberController,
            helperText: context.tr('profile.edit.cr_number_helper'),
            errorText: errorOf(crNumberError),
            keyboardType: TextInputType.number,
            isMonospace: true,
            enabled: enabled,
            onChanged: (_) => onChanged(),
          ),
      ],
    );
  }
}
