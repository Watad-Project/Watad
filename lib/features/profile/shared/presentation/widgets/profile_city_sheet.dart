import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/components/layout/app_menu_row.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/profile/shared/presentation/bloc/profile_city_search_bloc.dart';

/// The city search of the edit form (GRA-60), in a sheet. What the
/// contractor types searches places in Saudi Arabia; a tap on one finds its
/// city, and the sheet closes with that city.
class ProfileCitySheet extends StatefulWidget {
  const ProfileCitySheet({super.key});

  @override
  State<ProfileCitySheet> createState() => _ProfileCitySheetState();
}

class _ProfileCitySheetState extends State<ProfileCitySheet> {
  final TextEditingController _query = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // The keyboard opens with the sheet: typing is the only thing to do.
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProfileCitySearchBloc>();
    return BlocConsumer<ProfileCitySearchBloc, ProfileCitySearchState>(
      listenWhen: (previous, current) =>
          current.city != null && previous.city == null,
      listener: (context, state) => Navigator.of(context).pop(state.city),
      builder: (context, state) {
        final messageKey = state.messageKey;
        return SafeArea(
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('profile.edit.city_search_title'),
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  key: const Key('profile_city_search'),
                  controller: _query,
                  focusNode: _focus,
                  hint: context.tr('profile.edit.city_hint'),
                  textInputAction: TextInputAction.search,
                  enabled: !state.isResolving,
                  onChanged: (query) =>
                      bloc.add(ProfileCitySearchQueryChanged(query)),
                ),
                if (state.isSearching || state.isResolving) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: AppColors.primary,
                    backgroundColor: AppColors.border,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                if (messageKey != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                    child: Text(
                      context.tr(messageKey),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final suggestion in state.suggestions)
                          AppMenuRow(
                            icon: Icons.place_outlined,
                            label: suggestion.title,
                            subtitle: suggestion.subtitle,
                            onTap: state.isResolving
                                ? null
                                : () => bloc.add(
                                    ProfileCitySearchSuggestionPicked(
                                      suggestion,
                                    ),
                                  ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
