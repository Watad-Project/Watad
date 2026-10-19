import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_verified_name.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// A small business card for horizontal lists (home, saved, offers): the
/// business's photo in a circle (the default avatar without one), name with
/// the verified check, rating and number of projects, and where it works
/// when [location] is given.
class AppBusinessMiniCard extends StatelessWidget {
  const AppBusinessMiniCard({
    super.key,
    required this.name,
    required this.ratingLabel,
    required this.projectsLabel,
    this.isVerified = false,
    this.imageUrl,
    this.location,
    this.onTap,
  });

  final String name;

  /// E.g. "4.8".
  final String ratingLabel;

  /// E.g. "64 projects".
  final String projectsLabel;
  final bool isVerified;
  final String? imageUrl;

  /// Where the business works, e.g. its city, on its own line with a pin.
  final String? location;
  final VoidCallback? onTap;

  static const double _photoHeight = 80;
  static final TextStyle _nameStyle = AppTextStyles.label.copyWith(
    fontSize: 15,
  );
  static final TextStyle _ratingStyle = AppTextStyles.caption.copyWith(
    fontSize: 13,
  );

  /// The height a card needs at the phone's text size. Give it to the row or
  /// grid that holds the cards: with large text each line grows, and a
  /// fixed height would overflow (APP_ARCHITECTURE.md §10). Pass
  /// [withLocation] when the cards show a [location].
  static double heightOf(BuildContext context, {bool withLocation = false}) {
    final scaler = MediaQuery.textScalerOf(context);
    double lineHeight(TextStyle style) {
      // A space: one line's height comes from the font, not the letters.
      final painter = TextPainter(
        text: TextSpan(text: ' ', style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final ratingLine = math.max(16, lineHeight(_ratingStyle));
    return _photoHeight +
        AppSpacing.sm * 2 +
        lineHeight(_nameStyle) +
        2 +
        ratingLine +
        (withLocation ? 2 + ratingLine : 0) +
        // The card's border, and rounding.
        4;
  }

  @override
  Widget build(BuildContext context) {
    final nameStyle = _nameStyle;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // The business's photo, or the default avatar without one.
          SizedBox(
            height: _photoHeight,
            child: ColoredBox(
              color: AppColors.surfaceMuted,
              child: Center(child: AppAvatar(url: imageUrl, size: 56)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isVerified)
                  AppVerifiedName(name: name, style: nameStyle)
                else
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: nameStyle,
                  ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        '$ratingLabel · $projectsLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _ratingStyle,
                      ),
                    ),
                  ],
                ),
                if (location case final location?) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _ratingStyle,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
