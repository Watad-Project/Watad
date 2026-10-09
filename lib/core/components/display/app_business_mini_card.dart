import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_network_image.dart';
import 'package:watad/core/components/display/app_verified_name.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// A small business card for horizontal lists (home, saved, offers): photo,
/// name with the verified check, rating and number of projects.
class AppBusinessMiniCard extends StatelessWidget {
  const AppBusinessMiniCard({
    super.key,
    required this.name,
    required this.ratingLabel,
    required this.projectsLabel,
    this.isVerified = false,
    this.imageUrl,
    this.onTap,
  });

  final String name;

  /// E.g. "4.8".
  final String ratingLabel;

  /// E.g. "64 projects".
  final String projectsLabel;
  final bool isVerified;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nameStyle = AppTextStyles.label.copyWith(fontSize: 15);
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 80, child: AppNetworkImage(url: imageUrl)),
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
                        style: AppTextStyles.caption.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
