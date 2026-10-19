import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_image_viewer.dart';
import 'package:watad/core/components/display/app_network_image.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_document.dart';
import 'package:watad/features/review/admin/presentation/bloc/admin_review_documents_bloc.dart';

/// The files of one request, so the admin can check them before deciding.
/// An image shows here and opens full screen to zoom in; a PDF opens in the
/// phone's viewer. Both use a short-lived signed link, never a public URL.
class AdminReviewDocumentsPage extends StatelessWidget {
  const AdminReviewDocumentsPage({required this.businessId, super.key});

  final String businessId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: context.tr('review.documents_title'),
        onBack: () => context.pop(),
      ),
      body: BlocBuilder<AdminReviewDocumentsBloc, AdminReviewDocumentsState>(
        builder: (context, state) => switch (state) {
          AdminReviewDocumentsInitial() ||
          AdminReviewDocumentsLoadInProgress() => const AppLoadingIndicator(),
          AdminReviewDocumentsLoadFailure(:final failure) => AppErrorView(
            message: context.tr(failure.messageKey),
            onRetry: () => context.read<AdminReviewDocumentsBloc>().add(
              AdminReviewDocumentsFetched(businessId),
            ),
          ),
          AdminReviewDocumentsLoadSuccess(:final documents)
              when documents.isEmpty =>
            AppEmptyView(message: context.tr('review.no_documents')),
          AdminReviewDocumentsLoadSuccess(:final documents) => ListView(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            children: [
              for (final document in documents) ...[
                Text(
                  context.tr(_typeKey(document.documentType)),
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: AppSpacing.xs),
                if (document.isPdf)
                  AppButton(
                    label: context.tr('review.open_file'),
                    icon: Icons.picture_as_pdf_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _open(document),
                  )
                else
                  _ImagePreview(
                    url: document.url,
                    title: context.tr(_typeKey(document.documentType)),
                  ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ],
          ),
        },
      ),
    );
  }

  static String _typeKey(BusinessDocumentType type) => switch (type) {
    BusinessDocumentType.commercialRegistration =>
      'review.type_commercial_registration',
    BusinessDocumentType.vatCertificate => 'review.type_vat_certificate',
    BusinessDocumentType.nationalAddress => 'review.type_national_address',
    BusinessDocumentType.other => 'review.type_other',
  };

  static Future<void> _open(AdminReviewDocument document) =>
      launchUrl(Uri.parse(document.url), mode: LaunchMode.externalApplication);
}

/// An uploaded image; a tap opens it full screen to zoom in.
class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.url, required this.title});

  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
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
