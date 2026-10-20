import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:watad/core/config/env.dart';
import 'package:watad/core/di/app_slots.dart';
import 'package:watad/features/notifications/shared/datasource/local/notifications_push.dart';
import 'package:watad/features/notifications/shared/datasource/remote/notifications_remote_data_source.dart';
import 'package:watad/features/notifications/shared/datasource/repositories/notifications_repository_impl.dart';
import 'package:watad/features/notifications/shared/domain/repositories/notifications_repository.dart';
import 'package:watad/features/notifications/shared/domain/usecases/get_notifications_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/get_unread_notifications_count_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/mark_notifications_read_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/start_push_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/watch_new_notifications_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/watch_notification_taps_use_case.dart';
import 'package:watad/features/notifications/shared/presentation/bloc/notifications_bell_bloc.dart';
import 'package:watad/features/notifications/shared/presentation/bloc/notifications_bloc.dart';
import 'package:watad/features/notifications/shared/presentation/widgets/notifications_bell.dart';

/// Registers everything in lib/features/notifications/shared/.
void registerNotificationsDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<NotificationsRemoteDataSource>(
      () => NotificationsRemoteDataSourceImpl(getIt()),
    )
    // One for the app: OneSignal is started once.
    ..registerLazySingleton<NotificationsPush>(
      () => NotificationsPush(Env.oneSignalAppId, getIt()),
    )
    ..registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton(() => GetNotificationsUseCase(getIt()))
    ..registerLazySingleton(() => GetUnreadNotificationsCountUseCase(getIt()))
    ..registerLazySingleton(() => MarkNotificationsReadUseCase(getIt()))
    ..registerLazySingleton(() => StartPushUseCase(getIt()))
    ..registerLazySingleton(() => WatchNewNotificationsUseCase(getIt()))
    ..registerLazySingleton(() => WatchNotificationTapsUseCase(getIt()))
    ..registerFactory(() => NotificationsBloc(getIt(), getIt(), getIt()))
    ..registerFactory(
      () => NotificationsBellBloc(getIt(), getIt(), getIt(), getIt()),
    )
    // Lent to each role's home.
    ..registerFactory<Widget>(
      () => NotificationsBell(
        bloc: getIt<NotificationsBellBloc>()
          ..add(const NotificationsBellStarted()),
      ),
      instanceName: AppSlots.notificationsBell,
    );
}
