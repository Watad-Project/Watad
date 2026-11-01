import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/inputs/app_field_label.dart';
import 'package:watad/core/components/layout/app_menu_row.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// The business's city on the edit form (GRA-60): the city, or «لم تُحدَّد
/// المدينة», in a row that opens the city search. Only a city the search
/// found is saved, never typed text.
class ProfileCityField extends StatelessWidget {
  const ProfileCityField({this.city, this.onTap, super.key});

  final String? city;

  /// Opens the city search; null while the form can't change.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFieldLabel(label: context.tr('profile.edit.city')),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          padding: EdgeInsets.zero,
          child: AppMenuRow(
            key: const Key('profile_edit_city'),
            icon: Icons.location_city_outlined,
            label: city ?? context.tr('profile.edit.city_none'),
            onTap: onTap,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          context.tr('profile.edit.city_note'),
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
