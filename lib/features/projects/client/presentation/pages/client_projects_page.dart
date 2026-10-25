import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/projects/client/domain/entities/client_deed_verification_status.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_projects_filter.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_project_card.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_projects_skeleton.dart';

/// «مشاريعي»: the projects the client posted, newest first.
class ClientProjectsPage extends StatelessWidget {
  const ClientProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: context.tr('projects.client.title')),
      body: BlocBuilder<ClientProjectsBloc, ClientProjectsState>(
        // Loading, the list and errors fade into each other.
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

  Widget _body(BuildContext context, ClientProjectsState state) {
    final bloc = context.read<ClientProjectsBloc>();
    if (state.projects.isEmpty) {
      switch (state.status) {
        case ClientProjectsStatus.failure:
          return AppErrorView(
            key: const ValueKey('error'),
            message: context.tr(state.failure!.messageKey),
            onRetry: () => bloc.add(const ClientProjectsFetched()),
          );
        case ClientProjectsStatus.success:
          return RefreshIndicator(
            key: const ValueKey('empty'),
            onRefresh: () async => bloc.add(const ClientProjectsFetched()),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                AppEmptyView(
                  message: context.tr('projects.client.empty'),
                  icon: Icons.assignment_outlined,
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: AppButton(
                    key: const Key('client_projects_post_button'),
                    label: context.tr('projects.client.post_project'),
                    onPressed: () => _postProject(context, bloc),
                  ),
                ),
              ],
            ),
          );
        case ClientProjectsStatus.initial || ClientProjectsStatus.loading:
          return const ClientProjectsSkeleton(key: ValueKey('loading'));
      }
    }
    final projects = state.visibleProjects;
    return Column(
      key: const ValueKey('projects'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: AppFilterChips(
            key: const Key('client_projects_filter'),
            labels: [
              for (final filter in ClientProjectsFilter.values)
                context.tr(_filterLabelKey(filter)),
            ],
            selectedIndex: state.filter.index,
            onSelected: (index) => bloc.add(
              ClientProjectsFilterChanged(ClientProjectsFilter.values[index]),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => bloc.add(const ClientProjectsFetched()),
            child: projects.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      AppEmptyView(
                        message: context.tr('projects.client.empty_filter'),
                        icon: Icons.assignment_outlined,
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                    itemCount: projects.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      final route = _routeOf(project);
                      return ClientProjectCard(
                        project: project,
                        onTap: route == null
                            ? null
                            : () async {
                                await context.pushNamed(
                                  route,
                                  pathParameters: {'projectId': project.id},
                                );
                                // An accepted offer, a new deed or a decision
                                // on a task changes the project.
                                bloc.add(const ClientProjectsFetched());
                              },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  /// Where a tap on [project] goes: a rejected deed, its upload; waiting for
  /// offers, the offers; started or done, its tasks (GRA-47). A cancelled
  /// project opens nothing.
  static String? _routeOf(ClientProject project) => switch (project.status) {
    ProjectStatus.draft || ProjectStatus.open =>
      project.deedStatus == ClientDeedVerificationStatus.rejected
          ? ClientProjectsRoutes.projectDeedName
          : ClientProjectsRoutes.projectOffersName,
    ProjectStatus.inProgress ||
    ProjectStatus.completed => ClientProjectsRoutes.projectTasksName,
    ProjectStatus.cancelled => null,
  };

  static String _filterLabelKey(ClientProjectsFilter filter) =>
      switch (filter) {
        ClientProjectsFilter.done => 'projects.client.filter_done',
        ClientProjectsFilter.waiting => 'projects.client.filter_waiting',
        ClientProjectsFilter.inProgress => 'projects.client.filter_in_progress',
      };

  Future<void> _postProject(
    BuildContext context,
    ClientProjectsBloc bloc,
  ) async {
    await context.pushNamed(ClientProjectsRoutes.postProjectName);
    bloc.add(const ClientProjectsFetched());
  }
}
