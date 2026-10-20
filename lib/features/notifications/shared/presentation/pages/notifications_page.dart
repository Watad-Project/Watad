import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/features/notifications/shared/presentation/bloc/notifications_bloc.dart';
import 'package:watad/features/notifications/shared/presentation/widgets/notification_navigator.dart';
import 'package:watad/features/notifications/shared/presentation/widgets/notification_tile.dart';
import 'package:watad/features/notifications/shared/presentation/widgets/notifications_skeleton.dart';

/// «الإشعارات»: the user's notifications, newest first, live. A tap marks
/// one read and opens the screen of its event, when one is linked.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) => Scaffold(
        appBar: AppTopBar(
          title: context.tr('notifications.title'),
          onBack: () => context.pop(),
          actions: [
            if (state.unreadCount > 0)
              TextButton(
                onPressed: () => context.read<NotificationsBloc>().add(
                  const NotificationsAllRead(),
                ),
                child: Text(context.tr('notifications.mark_all_read')),
              ),
          ],
        ),
        // Loading, the list and errors fade into each other.
        body: AnimatedSwitcher(
          duration: AppMotion.enter,
          reverseDuration: AppMotion.exit,
          switchInCurve: AppMotion.enterCurve,
          switchOutCurve: AppMotion.exitCurve,
          child: _body(context, state),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, NotificationsState state) {
    final bloc = context.read<NotificationsBloc>();
    if (state.notifications.isEmpty) {
      if (state.status == NotificationsStatus.failure) {
        return AppErrorView(
          message: context.tr(state.failure!.messageKey),
          onRetry: () => bloc.add(const NotificationsFetched()),
        );
      }
      if (state.status != NotificationsStatus.success) {
        return const NotificationsSkeleton(key: ValueKey('loading'));
      }
    }
    final now = DateTime.now();
    return RefreshIndicator(
      key: const ValueKey('content'),
      onRefresh: () async => bloc.add(const NotificationsFetched()),
      child: state.notifications.isEmpty
          ? ListView(
              children: [
                AppEmptyView(
                  message: context.tr('notifications.empty'),
                  icon: Icons.notifications_none_rounded,
                ),
              ],
            )
          : ListView.separated(
              itemCount: state.notifications.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return NotificationTile(
                  notification: notification,
                  now: now,
                  onTap: () {
                    bloc.add(NotificationsOpened(notification));
                    NotificationNavigator.open(context, notification.data);
                  },
                );
              },
            ),
    );
  }
}
