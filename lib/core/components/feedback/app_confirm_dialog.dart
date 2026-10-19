import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_popup.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// A dialog that asks the user to confirm an action before proceeding
/// (e.g. withdrawing an offer or deleting an item).
///
/// Open it with [AppConfirmDialog.show], which uses [AppPopup.dialog] and
/// resolves to `true` when confirmed or `false`/`null` when cancelled.
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel,
    this.confirmVariant = AppButtonVariant.dark,
    this.onConfirm,
    this.onCancel,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;

  /// Defaults to `common.close` when omitted.
  final String? cancelLabel;
  final AppButtonVariant confirmVariant;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  /// Opens the confirmation dialog and returns `true` only when the user
  /// taps the confirm button.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String? cancelLabel,
    AppButtonVariant confirmVariant = AppButtonVariant.dark,
  }) {
    return AppPopup.dialog<bool>(
      context,
      builder: (dialogContext) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmVariant: confirmVariant,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveCancelLabel = cancelLabel ?? context.tr('common.close');

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: confirmLabel,
                    variant: confirmVariant,
                    onPressed:
                        onConfirm ?? () => Navigator.of(context).pop(true),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: effectiveCancelLabel,
                    variant: AppButtonVariant.secondary,
                    onPressed:
                        onCancel ?? () => Navigator.of(context).pop(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
