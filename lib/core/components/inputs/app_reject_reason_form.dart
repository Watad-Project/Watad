import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/inputs/app_radio_row.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// The form for rejecting something (a task update, a receipt, a refund, a
/// document): pick a reason, explain it, send.
///
/// The send button is enabled once a reason is picked. Sending with empty
/// details shows [detailsRequiredError] instead of calling [onSubmit].
class AppRejectReasonForm extends StatefulWidget {
  const AppRejectReasonForm({
    super.key,
    required this.title,
    required this.reasons,
    required this.detailsLabel,
    required this.requiredLabel,
    required this.detailsHint,
    required this.detailsRequiredError,
    required this.submitLabel,
    required this.onSubmit,
    this.isSubmitting = false,
  });

  final String title;
  final List<String> reasons;
  final String detailsLabel;
  final String requiredLabel;
  final String detailsHint;
  final String detailsRequiredError;
  final String submitLabel;

  /// Called with the index of the chosen reason and the trimmed details.
  final void Function(int reasonIndex, String details) onSubmit;
  final bool isSubmitting;

  @override
  State<AppRejectReasonForm> createState() => _AppRejectReasonFormState();
}

class _AppRejectReasonFormState extends State<AppRejectReasonForm> {
  final TextEditingController _details = TextEditingController();
  int? _reason;
  bool _showError = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  void _submit() {
    final details = _details.text.trim();
    if (details.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    widget.onSubmit(_reason!, details);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < widget.reasons.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xs),
          AppRadioRow(
            title: widget.reasons[i],
            selected: i == _reason,
            accent: AppRadioRowAccent.ink,
            onTap: widget.isSubmitting
                ? null
                : () => setState(() => _reason = i),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: widget.detailsLabel,
          requiredLabel: widget.requiredLabel,
          controller: _details,
          hint: widget.detailsHint,
          minLines: 3,
          maxLines: 5,
          enabled: !widget.isSubmitting,
          errorText: _showError ? widget.detailsRequiredError : null,
          onChanged: (_) {
            if (_showError) setState(() => _showError = false);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: widget.submitLabel,
          variant: AppButtonVariant.dark,
          isLoading: widget.isSubmitting,
          onPressed: _reason == null ? null : _submit,
        ),
      ],
    );
  }
}
