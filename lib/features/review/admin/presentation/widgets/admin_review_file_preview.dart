import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_image_viewer.dart';
import 'package:watad/core/components/display/app_network_image.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// A file the admin checks, through a short-lived signed link: an image
/// shows here and opens full screen to zoom in; a PDF opens in the phone's
/// viewer.
class AdminReviewFilePreview extends StatelessWidget {
  const AdminReviewFilePreview({
    required this.url,
    required this.title,
    required this.isPdf,
    super.key,
  });

  final String url;

  /// What the file is, e.g. «السجل التجاري».
  final String title;
  final bool isPdf;

  @override
  Widget build(BuildContext context) {
    if (isPdf) {
      return AppButton(
        label: context.tr('review.open_file'),
        icon: Icons.picture_as_pdf_outlined,
        variant: AppButtonVariant.secondary,
        onPressed: () =>
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      );
    }
    return Semantics(
      button: true,
      label: context.tr('review.view_full_size', args: [title]),
      excludeSemantics: true,
      child: AppCard(
        padding: EdgeInsetsDirectional.zero,
        onTap: () => AppImageViewer.show(context, url: url, title: title),
        child: Stack(
          children: [
            AppNetworkImage(url: url, height: 360, fit: BoxFit.contain),
            PositionedDirectional(
              end: AppSpacing.xs,
              bottom: AppSpacing.xs,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsetsDirectional.all(AppSpacing.xs),
                  child: Icon(
                    Icons.zoom_out_map_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
