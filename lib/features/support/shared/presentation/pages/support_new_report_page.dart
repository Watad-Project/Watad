import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_icon_tag.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_field_label.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/core/router/routes/support_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/support/shared/domain/entities/support_new_report.dart';
import 'package:watad/features/support/shared/domain/entities/support_target.dart';
import 'package:watad/features/support/shared/presentation/bloc/support_new_report_bloc.dart';
import 'package:watad/features/support/shared/presentation/widgets/support_labels.dart';

/// «بلاغ جديد» (GRA-63): a type, a description, and what it's about when
/// another screen opened it with a [target]. Closes with `true` once sent.
class SupportNewReportPage extends StatefulWidget {
  const SupportNewReportPage({this.target, super.key});

  final SupportTarget? target;

  @override
  State<SupportNewReportPage> createState() => _SupportNewReportPageState();
}

class _SupportNewReportPageState extends State<SupportNewReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  ReportType? _type;
  bool _showTypeError = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final type = _type;
    final isValid = _formKey.currentState?.validate() ?? false;
    setState(() => _showTypeError = type == null);
    if (type == null || !isValid) return;
    context.read<SupportNewReportBloc>().add(
      SupportNewReportSubmitted(
        SupportNewReport(
          type: type,
          description: _description.text,
          target: widget.target,
        ),
      ),
    );
  }

  String? _validate(String? value) {
    final length = (value ?? '').trim().length;
    if (length < SupportNewReport.minLength) {
      return context.tr('support.error_description_short');
    }
    if (length > SupportNewReport.maxLength) {
      return context.tr('support.error_description_long');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    return BlocConsumer<SupportNewReportBloc, SupportNewReportState>(
      listener: (context, state) {
        switch (state.status) {
          case SupportNewReportStatus.sent:
            context.showSuccessSnackBar(context.tr('support.sent'));
            // Back to where it was opened from; opened alone (a link), to
            // my reports, where it now shows.
            if (context.canPop()) {
              context.pop(true);
            } else {
              context.goNamed(SupportRoutes.supportReportsName);
            }
          case SupportNewReportStatus.failure:
            context.showErrorSnackBar(context.tr(state.failure!.messageKey));
          case SupportNewReportStatus.initial || SupportNewReportStatus.sending:
            break;
        }
      },
      builder: (context, state) {
        final isSending = state.status == SupportNewReportStatus.sending;
        return Scaffold(
          appBar: AppTopBar(
            title: context.tr('support.new_report'),
            onBack: () => context.pop(),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              children: [
                if (target != null) ...[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppIconTag(
                      label: context.tr(SupportLabels.targetKey(target.kind)),
                      icon: Icons.flag_outlined,
                      tone: AppTone.neutral,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppFieldLabel(
                  label: context.tr('support.type_label'),
                  isRequired: true,
                ),
                const SizedBox(height: AppSpacing.xs),
                AppFilterChips(
                  key: const Key('support_type'),
                  labels: [
                    for (final type in ReportType.values)
                      context.tr(SupportLabels.typeKey(type)),
                  ],
                  selectedIndex: _type == null
                      ? -1
                      : ReportType.values.indexOf(_type!),
                  onSelected: (index) => setState(() {
                    _type = ReportType.values[index];
                    _showTypeError = false;
                  }),
                  isWrapped: true,
                ),
                if (_showTypeError) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.tr('support.error_type'),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  key: const Key('support_description'),
                  label: context.tr('support.description_label'),
                  isRequired: true,
                  hint: context.tr('support.description_hint'),
                  controller: _description,
                  validator: _validate,
                  keyboardType: TextInputType.multiline,
                  minLines: 5,
                  maxLines: 10,
                ),
              ],
            ),
          ),
          bottomNavigationBar: AppActionBar(
            primary: AppButton(
              key: const Key('support_send'),
              label: context.tr('support.send'),
              isLoading: isSending,
              onPressed: isSending ? null : _submit,
            ),
          ),
        );
      },
    );
  }
}
