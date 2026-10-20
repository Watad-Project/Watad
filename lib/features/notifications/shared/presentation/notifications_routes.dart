import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/notifications_routes.dart';
import 'package:watad/features/notifications/shared/presentation/bloc/notifications_bloc.dart';
import 'package:watad/features/notifications/shared/presentation/pages/notifications_page.dart';

final List<RouteBase> notificationsRoutes = [
  GoRoute(
    name: NotificationsRoutes.notificationsName,
    path: NotificationsRoutes.notificationsPath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<NotificationsBloc>()
        ..add(const NotificationsFetched())
        ..add(const NotificationsChangesWatched()),
      child: const NotificationsPage(),
    ),
  ),
];
