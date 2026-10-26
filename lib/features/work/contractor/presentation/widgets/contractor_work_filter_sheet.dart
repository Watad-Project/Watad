import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_popup.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';
import 'package:watad/core/components/inputs/app_switch.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_filter.dart';
import 'package:watad/features/work/contractor/presentation/bloc/contractor_bid_bloc.dart';

class ContractorWorkFilterSheet extends StatefulWidget {
  const ContractorWorkFilterSheet({required this.initialFilter, super.key});

  final ContractorWorkFilter initialFilter;

  static Future<ContractorWorkFilter?> show(
    BuildContext context, {
    required ContractorWorkFilter initialFilter,
  }) {
    return AppPopup.sheet<ContractorWorkFilter>(
      context,
      builder: (_) => ContractorWorkFilterSheet(initialFilter: initialFilter),
    );
  }

  @override
  State<ContractorWorkFilterSheet> createState() =>
      _ContractorWorkFilterSheetState();
}

class _ContractorWorkFilterSheetState extends State<ContractorWorkFilterSheet> {
  late ContractorWorkSortBy _selectedSort = widget.initialFilter.sortBy;
  late bool _zeroOffersOnly = widget.initialFilter.zeroOffersOnly;
  late final TextEditingController _cityController = TextEditingController(
    text: widget.initialFilter.city,
  );
  late final TextEditingController _districtController = TextEditingController(
    text: widget.initialFilter.district,
  );
  late final TextEditingController _minBudgetController = TextEditingController(
    text:
        widget.initialFilter.minBudget != null &&
            widget.initialFilter.minBudget! > const Money.zero()
        ? '${widget.initialFilter.minBudget!.toJson()}'
        : '',
  );

  @override
  void dispose() {
    _cityController.dispose();
    _districtController.dispose();
    _minBudgetController.dispose();
    super.dispose();
  }

  int get _sortChipIndex => switch (_selectedSort) {
    ContractorWorkSortBy.newest => 0,
    ContractorWorkSortBy.highestBudget => 1,
    ContractorWorkSortBy.nearestDistance => 2,
  };

  void _onSortChipSelected(int index) {
    setState(() {
      _selectedSort = switch (index) {
        1 => ContractorWorkSortBy.highestBudget,
        2 => ContractorWorkSortBy.nearestDistance,
        _ => ContractorWorkSortBy.newest,
      };
    });
  }

  void _onReset() {
    Navigator.of(context).pop(
      ContractorWorkFilter(
        searchQuery: widget.initialFilter.searchQuery,
        projectType: widget.initialFilter.projectType,
      ),
    );
  }

  void _onApply() {
    final parsedMinMoney = ContractorBidBloc.parseBidMoney(
      _minBudgetController.text,
    );
    Navigator.of(context).pop(
      ContractorWorkFilter(
        searchQuery: widget.initialFilter.searchQuery,
        projectType: widget.initialFilter.projectType,
        city: _cityController.text.trim(),
        district: _districtController.text.trim(),
        minBudget: parsedMinMoney,
        sortBy: _selectedSort,
        zeroOffersOnly: _zeroOffersOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.tr('work.contractor.filter_title'),
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Location (الموقع: المدينة والحي)
                  Text(
                    context.tr('work.contractor.filter_location_section'),
                    style: AppTextStyles.label.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: context.tr(
                            'work.contractor.filter_city_label',
                          ),
                          controller: _cityController,
                          hint: context.tr('work.contractor.filter_city_hint'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppTextField(
                          label: context.tr(
                            'work.contractor.filter_district_label',
                          ),
                          controller: _districtController,
                          hint: context.tr(
                            'work.contractor.filter_district_hint',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // 2. Budget (الميزانية)
                  AppTextField(
                    label: context.tr(
                      'work.contractor.filter_min_budget_label',
                    ),
                    controller: _minBudgetController,
                    hint: context.tr('work.contractor.filter_min_budget_hint'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    isMonospace: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // 3. Distance & Budget Sorting (المسافة والترتيب)
                  Text(
                    context.tr('work.contractor.filter_sort_section'),
                    style: AppTextStyles.label.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppFilterChips(
                    isWrapped: true,
                    labels: [
                      context.tr('work.contractor.sort_newest'),
                      context.tr('work.contractor.sort_highest_budget'),
                      context.tr('work.contractor.sort_nearest_distance'),
                    ],
                    selectedIndex: _sortChipIndex,
                    onSelected: _onSortChipSelected,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // 4. Competition (المنافسة: 0 عروض)
                  AppSwitch(
                    label: context.tr(
                      'work.contractor.filter_zero_offers_label',
                    ),
                    value: _zeroOffersOnly,
                    onChanged: (value) =>
                        setState(() => _zeroOffersOnly = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: context.tr('work.contractor.filter_apply_button'),
                  onPressed: _onApply,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: context.tr('work.contractor.filter_reset_button'),
                  variant: AppButtonVariant.secondary,
                  onPressed: _onReset,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
