import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/review/admin/domain/entities/admin_license_details.dart';
import 'package:watad/features/review/admin/presentation/widgets/admin_review_file_preview.dart';

/// A license's business and the files it sent.
class AdminLicenseDetailsView extends StatelessWidget {
  const AdminLicenseDetailsView({required this.details, super.key});

  final AdminLicenseDetails details;

  @override
  Widget build(BuildContext context) {
    final notSet = context.tr('review.not_set');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: context.tr('review.business_title'),
          padding: EdgeInsetsDirectional.zero,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppKeyValueList(
          rows: [
            AppKeyValueRow(
              label: context.tr('review.field_company'),
              value: details.companyName,
            ),
            AppKeyValueRow(
              label: context.tr('review.field_cr_number'),
              value: details.crNumber,
              isMonospace: true,
            ),
            AppKeyValueRow(
              label: context.tr('review.field_specialty'),
              value: details.specializedField ?? notSet,
            ),
            AppKeyValueRow(
              label: context.tr('review.field_city'),
              value: details.city ?? notSet,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSectionHeader(
          title: context.tr('review.documents_title'),
          padding: EdgeInsetsDirectional.zero,
        ),
        const SizedBox(height: AppSpacing.xs),
        if (details.documents.isEmpty)
          Text(context.tr('review.no_documents'), style: AppTextStyles.caption)
        else
          for (final document in details.documents) ...[
            Text(
              context.tr(_typeKey(document.documentType)),
              style: AppTextStyles.label,
            ),
            const SizedBox(height: AppSpacing.xs),
            AdminReviewFilePreview(
              url: document.url,
              title: context.tr(_typeKey(document.documentType)),
              isPdf: document.isPdf,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }

  static String _typeKey(BusinessDocumentType type) => switch (type) {
    BusinessDocumentType.commercialRegistration =>
      'review.type_commercial_registration',
    BusinessDocumentType.vatCertificate => 'review.type_vat_certificate',
    BusinessDocumentType.nationalAddress => 'review.type_national_address',
    BusinessDocumentType.other => 'review.type_other',
  };
}
