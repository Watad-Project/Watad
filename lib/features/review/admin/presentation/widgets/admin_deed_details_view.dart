import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_image_viewer.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_network_image.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/review/admin/domain/entities/admin_deed_details.dart';
import 'package:watad/features/review/admin/presentation/widgets/admin_review_file_preview.dart';

/// A deed's project, the deed itself and the site photos.
class AdminDeedDetailsView extends StatelessWidget {
  const AdminDeedDetailsView({required this.details, super.key});

  final AdminDeedDetails details;

  static const double _photoSize = 96;

  @override
  Widget build(BuildContext context) {
    final notSet = context.tr('review.not_set');
    final budget = details.budget;
    final description = details.description?.trim() ?? '';
    final deedTitle = context.tr('review.deed_document');
    final photosTitle = context.tr('review.photos_title');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: context.tr('review.project_title'),
          padding: EdgeInsetsDirectional.zero,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppKeyValueList(
          rows: [
            AppKeyValueRow(
              label: context.tr('review.field_title'),
              value: details.title.isEmpty ? notSet : details.title,
            ),
            AppKeyValueRow(
              label: context.tr('review.field_budget'),
              value: budget == null
                  ? notSet
                  : AppMoneyText.format(context, budget),
            ),
            AppKeyValueRow(
              label: context.tr('review.field_city'),
              value: details.city ?? notSet,
            ),
            AppKeyValueRow(
              label: context.tr('review.field_district'),
              value: details.district ?? notSet,
            ),
          ],
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr('review.field_description'),
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(description, style: AppTextStyles.body),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppSectionHeader(title: deedTitle, padding: EdgeInsetsDirectional.zero),
        const SizedBox(height: AppSpacing.xs),
        AdminReviewFilePreview(
          url: details.deedUrl,
          title: deedTitle,
          isPdf: details.isDeedPdf,
        ),
        if (details.photoUrls.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(
            title: photosTitle,
            padding: EdgeInsetsDirectional.zero,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final url in details.photoUrls)
                Semantics(
                  button: true,
                  label: context.tr(
                    'review.view_full_size',
                    args: [photosTitle],
                  ),
                  excludeSemantics: true,
                  child: AppCard(
                    padding: EdgeInsetsDirectional.zero,
                    onTap: () => AppImageViewer.show(
                      context,
                      url: url,
                      title: photosTitle,
                    ),
                    child: AppNetworkImage(
                      url: url,
                      width: _photoSize,
                      height: _photoSize,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
