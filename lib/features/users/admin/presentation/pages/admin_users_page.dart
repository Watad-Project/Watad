import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/router/routes/admin_users_routes.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/users/admin/domain/entities/admin_users_filter.dart';
import 'package:watad/features/users/admin/presentation/bloc/admin_users_bloc.dart';
import 'package:watad/features/users/admin/presentation/widgets/admin_user_tile.dart';
import 'package:watad/features/users/admin/presentation/widgets/admin_users_skeleton.dart';

/// «المستخدمون»: every user, newest first, searched by name (or company
/// name) and narrowed by chips with their counts. A page loads as the list
/// reaches its end; a tap opens the user's page.
class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  static String _filterKey(AdminUsersFilter filter) => switch (filter) {
    AdminUsersFilter.all => 'users.filter_all',
    AdminUsersFilter.clients => 'users.filter_clients',
    AdminUsersFilter.businesses => 'users.filter_businesses',
    AdminUsersFilter.admins => 'users.filter_admins',
    AdminUsersFilter.suspended => 'users.filter_suspended',
  };

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AdminUsersBloc>();
    return Scaffold(
      appBar: AppTopBar(
        title: context.tr('users.title'),
        onBack: () => context.pop(),
      ),
      body: BlocBuilder<AdminUsersBloc, AdminUsersState>(
        builder: (context, state) => NotificationListener<ScrollNotification>(
          // Near the end of the list: the next page.
          onNotification: (notification) {
            final metrics = notification.metrics;
            if (metrics.axis == Axis.vertical && metrics.extentAfter < 400) {
              bloc.add(const AdminUsersMoreRequested());
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () async => bloc.add(const AdminUsersFetched()),
            child: ListView(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              children: [
                AppTextField(
                  key: const Key('admin_users_search'),
                  hint: context.tr('users.search_hint'),
                  textInputAction: TextInputAction.search,
                  onChanged: (text) => bloc.add(AdminUsersSearchChanged(text)),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppFilterChips(
                  key: const Key('admin_users_filter'),
                  isWrapped: true,
                  labels: [
                    for (final filter in AdminUsersFilter.values)
                      switch (state.counts) {
                        final counts? =>
                          '${context.tr(_filterKey(filter))} '
                              '${context.formatNumber(counts.of(filter))}',
                        null => context.tr(_filterKey(filter)),
                      },
                  ],
                  selectedIndex: state.filter.index,
                  onSelected: (index) => bloc.add(
                    AdminUsersFilterChanged(AdminUsersFilter.values[index]),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ..._body(context, bloc, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    AdminUsersBloc bloc,
    AdminUsersState state,
  ) {
    if (state.users.isEmpty) {
      return [
        switch (state.status) {
          AdminUsersStatus.failure => AppErrorView(
            message: context.tr(state.failure!.messageKey),
            onRetry: () => bloc.add(const AdminUsersFetched()),
          ),
          AdminUsersStatus.success => AppEmptyView(
            message: context.tr(
              state.search.isEmpty ? 'users.empty' : 'users.empty_search',
            ),
            icon: Icons.person_search_outlined,
          ),
          _ => const AdminUsersSkeleton(),
        },
      ];
    }
    final now = DateTime.now();
    return [
      for (final user in state.users) ...[
        AdminUserTile(
          key: ValueKey(user.id),
          user: user,
          now: now,
          onTap: () async {
            await context.pushNamed(
              AdminUsersRoutes.userDetailsName,
              pathParameters: {'userId': user.id},
            );
            // What the admin did there shows here too.
            bloc.add(const AdminUsersFetched());
          },
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      if (state.isLoadingMore)
        const Padding(
          padding: EdgeInsetsDirectional.all(AppSpacing.md),
          child: AppLoadingIndicator(),
        ),
    ];
  }
}
