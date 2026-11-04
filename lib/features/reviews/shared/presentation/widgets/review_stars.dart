import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_input.dart';

/// Five stars to tap, filled up to [rating] (0 for none yet). Each star
/// is a 48×48 button that says how many stars it gives.
class ReviewStars extends StatelessWidget {
  const ReviewStars({required this.rating, required this.onChanged, super.key});

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (
          var star = ReviewInput.minRating;
          star <= ReviewInput.maxRating;
          star++
        )
          IconButton(
            key: Key('review_star_$star'),
            tooltip: context.tr(
              'reviews.stars',
              args: [context.formatNumber(star)],
            ),
            isSelected: star <= rating,
            iconSize: 40,
            onPressed: () => onChanged(star),
            icon: Icon(
              star <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: star <= rating
                  ? AppColors.primary
                  : AppColors.controlBorder,
            ),
          ),
      ],
    );
  }
}
