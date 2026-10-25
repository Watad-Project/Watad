import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// The sheet the receipt box opens (GRA-52): a file (a PDF or an image
/// from the bank app), or a photo from the gallery. A choice closes the
/// sheet, then picks.
class ClientReceiptSourceSheet extends StatelessWidget {
  const ClientReceiptSourceSheet({
    required this.onPickFile,
    required this.onPickPhoto,
    super.key,
  });

  final VoidCallback onPickFile;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('payments.client.receipt_source_title'),
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: const Key('client_receipt_from_file'),
              label: context.tr('payments.client.receipt_from_file'),
              icon: Icons.description_outlined,
              onPressed: () {
                Navigator.of(context).pop();
                onPickFile();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              key: const Key('client_receipt_from_photos'),
              label: context.tr('payments.client.receipt_from_photos'),
              icon: Icons.photo_library_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () {
                Navigator.of(context).pop();
                onPickPhoto();
              },
            ),
          ],
        ),
      ),
    );
  }
}
