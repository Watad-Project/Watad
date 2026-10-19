import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/inputs/app_dropdown.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/home/client/domain/entities/client_contractor_filter.dart';
import 'package:watad/features/home/client/domain/entities/client_contractor_sort.dart';

/// The filter sheet of the «الكل» list: city, rating, completed projects
/// and order, as dropdowns two per row to keep the sheet short. Their lists
/// float over the sheet, so it keeps its size. Changes
/// apply with «عرض النتائج»; «مسح الكل» goes back to the defaults.
class ClientContractorsFilterSheet extends StatefulWidget {
  const ClientContractorsFilterSheet({
    required this.filter,
    required this.cities,
    required this.onApply,
    super.key,
  });

  final ClientContractorFilter filter;

  /// The cities contractors work in; the city filter lists them after
  /// «كل المدن».
  final List<String> cities;
  final ValueChanged<ClientContractorFilter> onApply;

  static const List<double> minRatings = [4, 3];
  static const List<int> minProjects = [10, 50, 100];

  @override
  State<ClientContractorsFilterSheet> createState() =>
      _ClientContractorsFilterSheetState();
}

class _ClientContractorsFilterSheetState
    extends State<ClientContractorsFilterSheet> {
  late ClientContractorFilter _draft = widget.filter;

  void _set(ClientContractorFilter filter) => setState(() => _draft = filter);

  @override
  Widget build(BuildContext context) {
    final cities = widget.cities;
    final dropdowns = <Widget>[
      AppDropdown<String?>(
        key: const Key('contractors_filter_city'),
        floating: true,
        label: context.tr('home.city_title'),
        value: _draft.city,
        options: [
          AppDropdownOption(value: null, title: context.tr('home.city_any')),
          for (final city in cities)
            AppDropdownOption(value: city, title: city),
        ],
        onChanged: (city) => _set(_draft.copyWith(city: () => city)),
      ),
      AppDropdown<double?>(
        key: const Key('contractors_filter_rating'),
        floating: true,
        label: context.tr('home.rating_title'),
        value: _draft.minRating,
        options: [
          AppDropdownOption(value: null, title: context.tr('home.rating_any')),
          for (final rating in ClientContractorsFilterSheet.minRatings)
            AppDropdownOption(
              value: rating,
              title: context.tr(
                'home.rating_at_least',
                args: [context.formatNumber(rating)],
              ),
            ),
        ],
        onChanged: (rating) => _set(_draft.copyWith(minRating: () => rating)),
      ),
      AppDropdown<int?>(
        key: const Key('contractors_filter_projects'),
        floating: true,
        label: context.tr('home.projects_title'),
        value: _draft.minProjects,
        options: [
          AppDropdownOption(
            value: null,
            title: context.tr('home.projects_any'),
          ),
          for (final projects in ClientContractorsFilterSheet.minProjects)
            AppDropdownOption(
              value: projects,
              title: context.plural(
                'home.projects_at_least',
                projects,
                args: [context.formatNumber(projects)],
              ),
            ),
        ],
        onChanged: (projects) =>
            _set(_draft.copyWith(minProjects: () => projects)),
      ),
      AppDropdown<ClientContractorSort>(
        key: const Key('contractors_filter_sort'),
        floating: true,
        label: context.tr('home.sort_title'),
        value: _draft.sort,
        options: [
          AppDropdownOption(
            value: ClientContractorSort.rating,
            title: context.tr('home.sort_rating'),
          ),
          AppDropdownOption(
            value: ClientContractorSort.projects,
            title: context.tr('home.sort_projects'),
          ),
        ],
        onChanged: (sort) => _set(_draft.copyWith(sort: sort)),
      ),
    ];
    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr('home.filters_title'), style: AppTextStyles.h2),
          // Two dropdowns per row.
          for (var i = 0; i < dropdowns.length; i += 2) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: dropdowns[i]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: i + 1 < dropdowns.length
                      ? dropdowns[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: context.tr('home.show_results'),
            onPressed: () {
              widget.onApply(_draft);
              Navigator.of(context).pop();
            },
          ),
          AppButton(
            label: context.tr('home.clear_filters'),
            variant: AppButtonVariant.link,
            onPressed: _draft.sheetFilterCount == 0
                ? null
                : () => _set(ClientContractorFilter(query: _draft.query)),
          ),
        ],
      ),
    );
  }
}
