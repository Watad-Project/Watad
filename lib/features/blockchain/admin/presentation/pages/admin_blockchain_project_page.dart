import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_project.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_sync_status.dart';
import 'package:watad/features/blockchain/admin/presentation/bloc/admin_blockchain_project_bloc.dart';
import 'package:watad/features/blockchain/admin/presentation/widgets/admin_blockchain_date.dart';
import 'package:watad/features/blockchain/admin/presentation/widgets/admin_blockchain_labels.dart';
import 'package:watad/features/blockchain/admin/presentation/widgets/admin_blockchain_skeleton.dart';

/// «مزامنة المشروع»: one contracted project's copy on the blockchain, its
/// last message, and «إعادة المزامنة الآن».
class AdminBlockchainProjectPage extends StatelessWidget {
  const AdminBlockchainProjectPage({super.key});

  /// How long after a resync the project is read again, to show what the
  /// sync did: it starts right away and usually takes a few seconds.
  static const Duration refreshAfterResync = Duration(seconds: 5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: context.tr('blockchain.admin.project_title'),
        onBack: () => context.pop(),
      ),
      body:
          BlocConsumer<AdminBlockchainProjectBloc, AdminBlockchainProjectState>(
            listenWhen: (previous, current) =>
                current.message != null && previous.message != current.message,
            listener: (context, state) {
              final message = state.message!;
              if (message.isError) {
                context.showErrorSnackBar(context.tr(message.key));
                return;
              }
              context.showSuccessSnackBar(context.tr(message.key));
              final projectId = state.projectId;
              final bloc = context.read<AdminBlockchainProjectBloc>();
              if (projectId == null) return;
              unawaited(
                Future<void>.delayed(refreshAfterResync, () {
                  if (!bloc.isClosed) {
                    bloc.add(AdminBlockchainProjectFetched(projectId));
                  }
                }),
              );
            },
            // Loading, the project and errors fade into each other.
            builder: (context, state) => AnimatedSwitcher(
              duration: AppMotion.enter,
              reverseDuration: AppMotion.exit,
              switchInCurve: AppMotion.enterCurve,
              switchOutCurve: AppMotion.exitCurve,
              child: _body(context, state),
            ),
          ),
    );
  }

  Widget _body(BuildContext context, AdminBlockchainProjectState state) {
    final bloc = context.read<AdminBlockchainProjectBloc>();
    final project = state.project;
    void reload() {
      if (state.projectId case final id?) {
        bloc.add(AdminBlockchainProjectFetched(id));
      }
    }

    if (project == null) {
      return switch (state.failure) {
        NotFoundFailure() => AppEmptyView(
          key: const ValueKey('not_found'),
          message: context.tr('blockchain.admin.not_found'),
          icon: Icons.search_off_rounded,
        ),
        final failure? => AppErrorView(
          key: const ValueKey('error'),
          message: context.tr(failure.messageKey),
          onRetry: reload,
        ),
        null => const Padding(
          key: ValueKey('loading'),
          padding: EdgeInsetsDirectional.all(AppSpacing.md),
          child: AdminBlockchainSkeleton(),
        ),
      };
    }
    return RefreshIndicator(
      key: const ValueKey('project'),
      onRefresh: () async => reload(),
      child: ListView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          _Header(project: project),
          const SizedBox(height: AppSpacing.md),
          _State(project: project),
          const SizedBox(height: AppSpacing.md),
          _Details(project: project),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: context.tr('blockchain.admin.resync'),
            isLoading: state.isBusy,
            onPressed: state.isBusy ? null : () => _resync(context, bloc),
          ),
        ],
      ),
    );
  }

  Future<void> _resync(
    BuildContext context,
    AdminBlockchainProjectBloc bloc,
  ) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: context.tr('blockchain.admin.resync_title'),
      message: context.tr('blockchain.admin.resync_message'),
      confirmLabel: context.tr('blockchain.admin.resync'),
    );
    if (confirmed == null) return;
    bloc.add(const AdminBlockchainProjectResynced());
  }
}

/// The project's title, client and contractor.
class _Header extends StatelessWidget {
  const _Header({required this.project});

  final AdminBlockchainProject project;

  @override
  Widget build(BuildContext context) {
    final noName = context.tr('blockchain.admin.no_name');
    final secondary = AppTextStyles.body.copyWith(
      color: AppColors.textSecondary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(project.title, style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.tr(
            'blockchain.admin.client_line',
            args: [project.ownerName ?? noName],
          ),
          style: secondary,
        ),
        Text(
          context.tr(
            'blockchain.admin.contractor_line',
            args: [project.contractorName ?? noName],
          ),
          style: secondary,
        ),
      ],
    );
  }
}

/// The state in its tone, why a project that needs attention does, and
/// the full last message of the sync.
class _State extends StatelessWidget {
  const _State({required this.project});

  final AdminBlockchainProject project;

  @override
  Widget build(BuildContext context) {
    final needsAttention =
        project.syncStatus == AdminBlockchainSyncStatus.failed;
    final message = project.lastMessage;
    return AppStatusCard(
      tone: AdminBlockchainLabels.statusTone(project.syncStatus),
      title: context.tr(AdminBlockchainLabels.statusKey(project.syncStatus)),
      subtitle: needsAttention
          ? context.tr('blockchain.admin.attention_explained')
          : null,
      reasonTitle: message == null
          ? null
          : context.tr('blockchain.admin.last_message'),
      reasonText: message,
    );
  }
}

/// Version, attempts and the times of the sync.
class _Details extends StatelessWidget {
  const _Details({required this.project});

  final AdminBlockchainProject project;

  @override
  Widget build(BuildContext context) {
    return AppKeyValueList(
      rows: [
        AppKeyValueRow(
          label: context.tr('blockchain.admin.version'),
          value: context.formatNumber(project.version),
        ),
        AppKeyValueRow(
          label: context.tr('blockchain.admin.attempts'),
          value: context.formatNumber(project.attempts),
        ),
        AppKeyValueRow(
          label: context.tr('blockchain.admin.last_attempt'),
          value: AdminBlockchainDate.format(context, project.lastAttemptAt),
        ),
        AppKeyValueRow(
          label: context.tr('blockchain.admin.next_attempt'),
          value: AdminBlockchainDate.format(context, project.nextAttemptAt),
        ),
        AppKeyValueRow(
          label: context.tr('blockchain.admin.last_sync'),
          value: AdminBlockchainDate.format(context, project.syncedAt),
        ),
      ],
    );
  }
}
