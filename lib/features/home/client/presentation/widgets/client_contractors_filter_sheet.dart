import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/home/client/domain/entities/client_contractor_filter.dart';
import 'package:watad/features/home/client/domain/entities/client_contractor_sort.dart';

/// The filter sheet of the «الكل» list: city, rating, completed projects
/// and order. Changes apply with «عرض النتائج»; «مسح الكل» goes back to
/// the defaults.
class ClientContractorsFilterSheet extends StatefulWidget {
  const ClientContractorsFilterSheet({
    required this.filter,
    required this.cities,
    required this.onApply,
    super.key,
  });

  final ClientContractorFilter filter;

  /// The cities contractors work in. Empty: no city part.
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
    const ratings = ClientContractorsFilterSheet.minRatings;
    const projects = ClientContractorsFilterSheet.minProjects;
    const sorts = ClientContractorSort.values;
    final city = _draft.city;
    final minRating = _draft.minRating;
    final minProjects = _draft.minProjects;
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
          if (cities.isNotEmpty)
            _Section(
              title: context.tr('home.city_title'),
              child: AppFilterChips(
                isWrapped: true,
                labels: [context.tr('home.city_any'), ...cities],
                selectedIndex: city == null ? 0 : cities.indexOf(city) + 1,
                onSelected: (index) => _set(
                  _draft.copyWith(
                    city: () => index == 0 ? null : cities[index - 1],
                  ),
                ),
              ),
            ),
          _Section(
            title: context.tr('home.rating_title'),
            child: AppFilterChips(
              isWrapped: true,
              labels: [
                context.tr('home.rating_any'),
                for (final r in ratings)
                  context.tr(
                    'home.rating_at_least',
                    args: [context.formatNumber(r)],
                  ),
              ],
              selectedIndex: minRating == null
                  ? 0
                  : ratings.indexOf(minRating) + 1,
              onSelected: (index) => _set(
                _draft.copyWith(
                  minRating: () => index == 0 ? null : ratings[index - 1],
                ),
              ),
            ),
          ),
          _Section(
            title: context.tr('home.projects_title'),
            child: AppFilterChips(
              isWrapped: true,
              labels: [
                context.tr('home.projects_any'),
                for (final p in projects)
                  context.plural(
                    'home.projects_at_least',
                    p,
                    args: [context.formatNumber(p)],
                  ),
              ],
              selectedIndex: minProjects == null
                  ? 0
                  : projects.indexOf(minProjects) + 1,
              onSelected: (index) => _set(
                _draft.copyWith(
                  minProjects: () => index == 0 ? null : projects[index - 1],
                ),
              ),
            ),
          ),
          _Section(
            title: context.tr('home.sort_title'),
            child: AppFilterChips(
              isWrapped: true,
              labels: [
                context.tr('home.sort_rating'),
                context.tr('home.sort_projects'),
              ],
              selectedIndex: sorts.indexOf(_draft.sort),
              onSelected: (index) => _set(_draft.copyWith(sort: sorts[index])),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: context.tr('home.show_results'),
            onPressed: () {
              widget.onApply(_draft);
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: AppSpacing.xs),
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}
