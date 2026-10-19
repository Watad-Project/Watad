import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// Asks before a serious action (remove a listing, suspend a user): what
/// will happen, then confirm or cancel. With [reasonLabel], a reason is
/// required before confirming, e.g. one the other person will read.
///
/// Open it with [AppConfirmDialog.show]:
///
/// ```dart
/// final reason = await AppConfirmDialog.show(
///   context,
///   title: context.tr('reports.remove_title'),
///   message: context.tr('reports.remove_message'),
///   confirmLabel: context.tr('reports.remove_listing'),
///   reasonLabel: context.tr('common.reason'),
/// );
/// if (reason != null) bloc.add(...);
/// ```
class AppConfirmDialog extends StatefulWidget {
  const AppConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.reasonLabel,
    super.key,
  });

  final String title;

  /// What will happen, in a sentence or two.
  final String message;
  final String confirmLabel;

  /// The label of the required reason field. Null asks for no reason.
  final String? reasonLabel;

  /// Shows the dialog. Returns the trimmed reason (empty without
  /// [reasonLabel]) when confirmed, or null when cancelled.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String? reasonLabel,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        reasonLabel: reasonLabel,
      ),
    );
  }

  @override
  State<AppConfirmDialog> createState() => _AppConfirmDialogState();
}

class _AppConfirmDialogState extends State<AppConfirmDialog> {
  final TextEditingController _reason = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _reason.text.trim();
    if (widget.reasonLabel != null && reason.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.xs),
            Text(widget.message, style: AppTextStyles.body),
            if (widget.reasonLabel case final label?) ...[
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: label,
                isRequired: true,
                controller: _reason,
                hint: context.tr('common.write_reason'),
                errorText: _showError
                    ? context.tr('common.reason_required')
                    : null,
                minLines: 2,
                maxLines: 4,
                onChanged: (_) {
                  if (_showError) setState(() => _showError = false);
                },
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: widget.confirmLabel,
                    variant: AppButtonVariant.dark,
                    onPressed: _confirm,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: context.tr('common.cancel'),
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(),
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
