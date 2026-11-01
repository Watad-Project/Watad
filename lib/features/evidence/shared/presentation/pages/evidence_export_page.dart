import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_refusal.dart';
import 'package:watad/features/evidence/shared/domain/entities/project_evidence.dart';
import 'package:watad/features/evidence/shared/domain/usecases/export_project_evidence_use_case.dart';
import 'package:watad/features/evidence/shared/presentation/bloc/evidence_export_bloc.dart';
import 'package:watad/features/evidence/shared/presentation/widgets/evidence_pdf.dart';

/// «تصدير سجل المشروع»: collects the project's signed evidence from the
/// server, then shares, saves or prints it as a PDF. Without the chain's
/// part there's no file: it would mislead.
class EvidenceExportPage extends StatefulWidget {
  const EvidenceExportPage({required this.projectId, super.key});

  final String projectId;

  @override
  State<EvidenceExportPage> createState() => _EvidenceExportPageState();
}

class _EvidenceExportPageState extends State<EvidenceExportPage> {
  /// Built once, on the first share or print.
  Uint8List? _bytes;
  String? _fileName;
  bool _isBuilding = false;

  /// Refusals a retry won't change.
  static final Set<String> _final = {
    ExportProjectEvidenceUseCase.messageKeyOf(EvidenceRefusal.notAllowed),
    ExportProjectEvidenceUseCase.messageKeyOf(EvidenceRefusal.notFound),
    ExportProjectEvidenceUseCase.messageKeyOf(EvidenceRefusal.notOnChain),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: context.tr('evidence.export_title'),
        onBack: () => context.pop(),
      ),
      body: BlocBuilder<EvidenceExportBloc, EvidenceExportState>(
        builder: (context, state) => AnimatedSwitcher(
          duration: AppMotion.enter,
          reverseDuration: AppMotion.exit,
          switchInCurve: AppMotion.enterCurve,
          switchOutCurve: AppMotion.exitCurve,
          child: switch (state) {
            EvidenceExportInitial() || EvidenceExportLoadInProgress() =>
              const _Collecting(key: ValueKey('collecting')),
            EvidenceExportLoadFailure(:final failure) => _failure(failure),
            EvidenceExportLoadSuccess(:final evidence) => _Ready(
              key: const ValueKey('ready'),
              evidence: evidence,
            ),
          },
        ),
      ),
      bottomNavigationBar: BlocBuilder<EvidenceExportBloc, EvidenceExportState>(
        builder: (context, state) => switch (state) {
          EvidenceExportLoadSuccess(:final evidence) => AppActionBar(
            primary: AppButton(
              label: context.tr('evidence.share'),
              isLoading: _isBuilding,
              onPressed: _isBuilding ? null : () => _share(evidence),
            ),
            secondary: AppButton(
              label: context.tr('evidence.print'),
              variant: AppButtonVariant.secondary,
              onPressed: _isBuilding ? null : () => _print(evidence),
            ),
          ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  Widget _failure(Failure failure) {
    final message = context.tr(failure.messageKey);
    if (_final.contains(failure.messageKey)) {
      return AppEmptyView(
        key: const ValueKey('refused'),
        message: message,
        icon: Icons.block_rounded,
      );
    }
    return AppErrorView(
      key: const ValueKey('error'),
      message: message,
      onRetry: () => context.read<EvidenceExportBloc>().add(
        EvidenceExportStarted(widget.projectId),
      ),
    );
  }

  /// The PDF's bytes, made once in the app's language.
  Future<Uint8List?> _file(ProjectEvidence evidence) async {
    if (_bytes case final bytes?) return bytes;
    setState(() => _isBuilding = true);
    try {
      final assets = await EvidencePdfAssets.load();
      if (!mounted) return null;
      final pdf = EvidencePdf.of(context, evidence, assets);
      // Translated now, laid out after.
      final document = pdf.document();
      final bytes = await document.save();
      _fileName = pdf.fileName;
      return _bytes = bytes;
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
      if (mounted) context.showErrorSnackBar(context.tr('evidence.pdf_failed'));
      return null;
    } finally {
      if (mounted) setState(() => _isBuilding = false);
    }
  }

  Future<void> _share(ProjectEvidence evidence) async {
    final bytes = await _file(evidence);
    if (bytes == null || !mounted) return;
    await Printing.sharePdf(
      bytes: bytes,
      filename: _fileName ?? 'watad-evidence.pdf',
      subject: context.tr('evidence.pdf_title'),
    );
  }

  Future<void> _print(ProjectEvidence evidence) async {
    final bytes = await _file(evidence);
    if (bytes == null || !mounted) return;
    await Printing.layoutPdf(
      name: _fileName ?? 'watad-evidence.pdf',
      onLayout: (_) async => bytes,
    );
  }
}

/// The server is reading the chain: it can take a few seconds.
class _Collecting extends StatelessWidget {
  const _Collecting({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoadingIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.tr('evidence.collecting'),
              style: AppTextStyles.label,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.tr('evidence.collecting_hint'),
              style: AppTextStyles.body.copyWith(color: AppColors.textBody),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// What the file holds: whether the chain matches, and the export.
class _Ready extends StatelessWidget {
  const _Ready({required this.evidence, super.key});

  final ProjectEvidence evidence;

  @override
  Widget build(BuildContext context) {
    final locale = context.isArabic
        ? AppLocalization.arabic.languageCode
        : AppLocalization.english.languageCode;
    String time(DateTime value) =>
        DateFormat.yMMMd(locale).add_jm().format(value.toLocal());
    final mismatches =
        evidence.chainFields.where((field) => !field.matches).length +
        evidence.chainMilestones.where((task) => !task.matches).length +
        evidence.chainPayments.where((payment) => !payment.matches).length;
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        Text(evidence.project.title, style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.md),
        AppStatusCard(
          tone: evidence.matches ? AppTone.success : AppTone.danger,
          title: context.tr(
            evidence.matches
                ? 'evidence.chain_matches'
                : 'evidence.chain_differs',
          ),
          subtitle: evidence.matches
              ? context.tr('evidence.chain_matches_hint')
              : context.tr(
                  'evidence.chain_differs_hint',
                  args: [context.formatNumber(mismatches)],
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppKeyValueList(
          onCopied: (_) =>
              context.showSuccessSnackBar(context.tr('evidence.copied')),
          rows: [
            AppKeyValueRow(
              label: context.tr('evidence.pdf_export_id'),
              value: evidence.exportId,
              isMonospace: true,
              isCopyable: true,
            ),
            AppKeyValueRow(
              label: context.tr('evidence.pdf_exported_at'),
              value: time(evidence.exportedAt),
            ),
            AppKeyValueRow(
              label: context.tr('evidence.pdf_last_sync_label'),
              value: evidence.lastSyncedAt == null
                  ? context.tr('evidence.none')
                  : time(evidence.lastSyncedAt!),
            ),
            AppKeyValueRow(
              label: context.tr('evidence.pdf_fingerprint'),
              value: evidence.fingerprint,
              isMonospace: true,
              isCopyable: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.tr('evidence.ready_hint'),
          style: AppTextStyles.body.copyWith(color: AppColors.textBody),
        ),
      ],
    );
  }
}
