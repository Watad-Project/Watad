import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/components/inputs/app_field_label.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_identity.dart';
import 'package:watad/features/profile/shared/presentation/widgets/profile_format.dart';

/// The ID/iqama number and phone the user gave at sign-up (GRA-60),
/// read-only: nothing in the app changes them.
class ProfileIdentitySection extends StatelessWidget {
  const ProfileIdentitySection({required this.identity, super.key});

  final ProfileIdentity identity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFieldLabel(label: context.tr('profile.edit.identity_title')),
        const SizedBox(height: AppSpacing.xs),
        AppKeyValueList(
          rows: [
            AppKeyValueRow(
              label: context.tr('profile.edit.national_id'),
              value: identity.nationalId,
              isMonospace: true,
            ),
            AppKeyValueRow(
              label: context.tr('profile.edit.phone'),
              value: ProfileFormat.phone(identity.phone),
              isMonospace: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          context.tr('profile.edit.identity_note'),
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
