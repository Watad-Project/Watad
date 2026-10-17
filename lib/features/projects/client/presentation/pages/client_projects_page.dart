import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_project_card.dart';

class ClientProjectsPage extends StatelessWidget {
  const ClientProjectsPage({this.onPostProject, super.key});

  final VoidCallback? onPostProject;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar(title: 'projects.client.list_title'.tr()),
      body: BlocBuilder<ClientProjectsBloc, ClientProjectsState>(
        builder: (context, state) => switch (state) {
          ClientProjectsInitial() ||
          ClientProjectsLoadInProgress() => const AppLoadingIndicator(),
          ClientProjectsLoadFailure(:final failure) => AppErrorView(
            message: failure.messageKey.tr(),
            onRetry: () => context.read<ClientProjectsBloc>().add(
              const ClientProjectsFetched(),
            ),
          ),
          ClientProjectsLoadSuccess(:final projects) when projects.isEmpty =>
            RefreshIndicator(
              onRefresh: () async {
                context.read<ClientProjectsBloc>().add(
                  const ClientProjectsFetched(),
                );
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.7,
                    child: AppEmptyView(
                      title: 'projects.client.empty_title'.tr(),
                      message: 'projects.client.empty_message'.tr(),
                      actionLabel: onPostProject != null
                          ? 'projects.client.empty_action'.tr()
                          : null,
                      onAction: onPostProject,
                    ),
                  ),
                ],
              ),
            ),
          ClientProjectsLoadSuccess(:final projects) => RefreshIndicator(
            onRefresh: () async {
              context.read<ClientProjectsBloc>().add(
                const ClientProjectsFetched(),
              );
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: projects.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final project = projects[index];
                return ClientProjectCard(
                  project: project,
                  onTap: () => context.pushNamed(
                    ClientProjectsRoutes.projectOffersName,
                    pathParameters: {'projectId': project.id},
                  ),
                );
              },
            ),
          ),
        },
      ),
    );
  }
}
