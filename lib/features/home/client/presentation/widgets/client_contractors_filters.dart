import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/home/client/domain/entities/client_contractor_filter.dart';

/// The filters of the «الكل» list: the company name and the lowest rating.
/// The name is sent once typing pauses.
class ClientContractorsFilters extends StatefulWidget {
  const ClientContractorsFilters({
    required this.filter,
    required this.onChanged,
    super.key,
  });

  final ClientContractorFilter filter;
  final ValueChanged<ClientContractorFilter> onChanged;

  /// The rating chips, after «كل التقييمات».
  static const List<double> minRatings = [4, 3];

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

  @override
  Widget build(BuildContext context) {
    final filter = widget.filter;
    const ratings = ClientContractorsFilters.minRatings;
    final minRating = filter.minRating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _name,
          hint: context.tr('home.search_contractors'),
          textInputAction: TextInputAction.search,
          onChanged: _onNameChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppFilterChips(
          labels: [
            context.tr('home.rating_any'),
            for (final r in ratings)
              context.tr(
                'home.rating_at_least',
                args: [context.formatNumber(r)],
              ),
          ],
          selectedIndex: minRating == null ? 0 : ratings.indexOf(minRating) + 1,
          onSelected: (index) => widget.onChanged(
            filter.copyWith(
              minRating: () => index == 0 ? null : ratings[index - 1],
            ),
          ),
        ),
      ],
    );
  }
}
