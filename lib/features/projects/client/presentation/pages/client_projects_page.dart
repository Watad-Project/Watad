import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_project_card.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_projects_skeleton.dart';

/// «مشاريعي»: the projects the client posted, newest first.
class ClientProjectsPage extends StatelessWidget {
  const ClientProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: context.tr('projects.title')),
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
              children: [
                AppEmptyView(
                  message: context.tr('projects.empty'),
                  icon: Icons.assignment_outlined,
                ),
              ],
            ),
          );
        case ClientProjectsStatus.initial || ClientProjectsStatus.loading:
          return const ClientProjectsSkeleton(key: ValueKey('loading'));
      }
    }
    return RefreshIndicator(
      key: const ValueKey('projects'),
      onRefresh: () async => bloc.add(const ClientProjectsFetched()),
      child: ListView.separated(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        itemCount: state.projects.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final project = state.projects[index];
          return ClientProjectCard(
            project: project,
            onTap: () async {
              await context.pushNamed(
                ClientProjectsRoutes.projectOffersName,
                pathParameters: {'projectId': project.id},
              );
              // An accepted offer changes the project.
              bloc.add(const ClientProjectsFetched());
            },
          );
        },
      ),
    );
  }
}
