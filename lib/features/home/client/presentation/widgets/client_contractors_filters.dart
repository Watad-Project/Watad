import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_icon_button.dart';
import 'package:watad/core/components/feedback/app_popup.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/home/client/domain/entities/client_contractor_filter.dart';
import 'package:watad/features/home/client/presentation/widgets/client_contractors_filter_sheet.dart';

/// The top of the «الكل» list: the name search (sent once typing pauses)
/// and the button of the filter sheet, with how many filters are on.
class ClientContractorsFilters extends StatefulWidget {
  const ClientContractorsFilters({
    required this.filter,
    required this.cities,
    required this.onChanged,
    super.key,
  });

  final ClientContractorFilter filter;
  final List<String> cities;
  final ValueChanged<ClientContractorFilter> onChanged;

  @override
  State<ClientContractorsFilters> createState() =>
      _ClientContractorsFiltersState();
}

class _ClientContractorsFiltersState extends State<ClientContractorsFilters> {
  static const Duration _typingPause = Duration(milliseconds: 400);

  late final TextEditingController _name = TextEditingController(
    text: widget.filter.query,
  );
  Timer? _typing;

  @override
  void dispose() {
    _typing?.cancel();
    _name.dispose();
    super.dispose();
  }

  void _onNameChanged(String text) {
    _typing?.cancel();
    _typing = Timer(
      _typingPause,
      () => widget.onChanged(widget.filter.copyWith(query: text.trim())),
    );
  }

  void _openSheet() {
    AppPopup.sheet<void>(
      context,
      builder: (_) => ClientContractorsFilterSheet(
        filter: widget.filter,
        cities: widget.cities,
        onApply: widget.onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.filter.sheetFilterCount;
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            controller: _name,
            hint: context.tr('home.search_contractors'),
            textInputAction: TextInputAction.search,
            onChanged: _onNameChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Badge(
          isLabelVisible: count > 0,
          label: Text(context.formatNumber(count)),
          backgroundColor: AppColors.primary,
          child: AppIconButton(
            icon: Icons.tune_rounded,
            tooltip: context.tr('home.filters_title'),
            onPressed: _openSheet,
          ),
        ),
      ],
    );
  }
}
