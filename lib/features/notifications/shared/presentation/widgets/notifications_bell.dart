import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_top_toast.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/router/routes/notifications_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/features/notifications/shared/presentation/bloc/notifications_bell_bloc.dart';
import 'package:watad/features/notifications/shared/presentation/widgets/notification_target_navigator.dart';

/// The bell on each role's home: the unread count, live; the list on a tap;
/// a notification that arrives while the app is open, as an [AppTopToast]
/// over any screen (instead of a push); and where a tapped push leads. The injection file passes the
/// bloc in and lends the bell to the homes (AppSlots.notificationsBell); it
/// closes the bloc when it goes away.
class NotificationsBell extends StatefulWidget {
  const NotificationsBell({required this.bloc, super.key});

  final NotificationsBellBloc bloc;

  @override
  State<NotificationsBell> createState() => _NotificationsBellState();
}

class _NotificationsBellState extends State<NotificationsBell> {
  /// The state the bell last reacted to: each arrival and tap once.
  late NotificationsBellState _seen;

  @override
  void initState() {
    super.initState();
    _seen = widget.bloc.state;
  }

  @override
  void dispose() {
    widget.bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: widget.bloc,
    child: BlocConsumer<NotificationsBellBloc, NotificationsBellState>(
      listener: _onChange,
      builder: (context, state) {
        final count = state.unreadCount;
        return IconButton(
          tooltip: context.plural(
            'notifications.bell',
            count,
            args: [context.formatNumber(count)],
          ),
          onPressed: () => _openList(context),
          icon: Badge(
            isLabelVisible: count > 0,
            backgroundColor: AppColors.primary,
            label: Text(context.formatNumber(count)),
            child: const Icon(Icons.notifications_none_rounded),
          ),
        );
      },
    ),
  );

  void _onChange(BuildContext context, NotificationsBellState state) {
    final previous = _seen;
    _seen = state;
    // A notification arrived while the app is open: on top of whatever
    // screen is showing (the bell's tab stays alive under every page).
    final arrived = state.arrived;
    if (arrived != null && !identical(arrived, previous.arrived)) {
      AppTopToast.show(
        context,
        title: arrived.title,
        message: arrived.body,
        // Opening it reads it, and goes where it leads.
        onTap: () {
          widget.bloc.add(NotificationsBellOpened(arrived.id));
          if (arrived.target case final target?) {
            NotificationTargetNavigator.open(context, target);
          }
        },
      );
    }
    // A push was tapped: open where it leads.
    final tapped = state.tapped;
    if (tapped != null && !identical(tapped, previous.tapped)) {
      if (tapped.target case final target?) {
        NotificationTargetNavigator.open(context, target);
      }
    }
  }

  Future<void> _openList(BuildContext context) async {
    await context.pushNamed(NotificationsRoutes.notificationsName);
    widget.bloc.add(const NotificationsBellCountRequested());
  }
}
