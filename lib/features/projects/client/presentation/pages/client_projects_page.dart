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

/// Screen listing all client projects with their statuses and incoming offers.
class ClientProjectsPage extends StatelessWidget {
  const ClientProjectsPage({super.key, this.onPostProject});

  final VoidCallback? onPostProject;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar(title: context.tr('projects.client.list_title')),
      body: BlocBuilder<ClientProjectsBloc, ClientProjectsState>(
        builder: (context, state) => switch (state) {
          ClientProjectsInitial() ||
          ClientProjectsLoadInProgress() => const AppLoadingIndicator(),
          ClientProjectsLoadFailure(:final failure) => AppErrorView(
            message: context.tr(failure.messageKey),
            onRetry: () => context.read<ClientProjectsBloc>().add(
              const ClientProjectsFetched(),
            ),
          ),
          ClientProjectsLoadSuccess(:final projects) when projects.isEmpty =>
            AppEmptyView(
              icon: Icons.assignment_outlined,
              title: context.tr('projects.client.empty_title'),
              message: context.tr('projects.client.empty'),
              actionLabel: context.tr('projects.client.create_project_action'),
              onAction: onPostProject ?? () {},
            ),
          ClientProjectsLoadSuccess(:final projects) => RefreshIndicator(
            onRefresh: () async {
              context.read<ClientProjectsBloc>().add(
                const ClientProjectsFetched(),
              );
            },
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: projects.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final project = projects[index];
                return ClientProjectCard(
                  project: project,
                  onTap: () {
                    context.pushNamed(
                      ClientProjectsRoutes.projectOffersName,
                      pathParameters: {'id': project.id},
                    );
                  },
                  onReuploadDeed: onPostProject,
                );
              },
            ),
          ),
        },
      ),
    );
  }
}
