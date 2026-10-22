import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_closure.dart';

/// Closes a ticket: the answer the user reads (required, at most
/// [AdminReportClosure.maxNoteLength] characters), then «تم الحل» or «رفض».
class AdminReportCloseForm extends StatefulWidget {
  const AdminReportCloseForm({
    required this.isBusy,
    required this.onSubmit,
    super.key,
  });

  /// An action on the ticket is being sent.
  final bool isBusy;

  /// Called with [ReportStatus.resolved] or [ReportStatus.dismissed] and
  /// the trimmed answer.
  final void Function(ReportStatus status, String note) onSubmit;

  @override
  State<AdminReportCloseForm> createState() => _AdminReportCloseFormState();
}

class _AdminReportCloseFormState extends State<AdminReportCloseForm> {
  final TextEditingController _note = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _submit(ReportStatus status) {
    final note = _note.text.trim();
    if (note.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    widget.onSubmit(status, note);
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = widget.isBusy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: const Key('admin_report_note'),
          label: context.tr('reports.note_label'),
          isRequired: true,
          controller: _note,
          hint: context.tr('reports.note_placeholder'),
          // The user reads it, so say so next to the field.
          helperText: context.tr('reports.note_hint'),
          errorText: _showError ? context.tr('reports.note_required') : null,
          minLines: 3,
          maxLines: 6,
          enabled: !isBusy,
          inputFormatters: [
            LengthLimitingTextInputFormatter(AdminReportClosure.maxNoteLength),
          ],
          onChanged: (_) {
            if (_showError) setState(() => _showError = false);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: context.tr('reports.resolve'),
                variant: AppButtonVariant.dark,
                isLoading: isBusy,
                onPressed: isBusy ? null : () => _submit(ReportStatus.resolved),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: context.tr('reports.reject'),
                variant: AppButtonVariant.secondary,
                onPressed: isBusy
                    ? null
                    : () => _submit(ReportStatus.dismissed),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
