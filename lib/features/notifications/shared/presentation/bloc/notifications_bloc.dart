import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification.dart';
import 'package:watad/features/notifications/shared/domain/usecases/get_notifications_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/mark_notifications_read_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/watch_notification_changes_use_case.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

/// «الإشعارات»: the user's notifications, newest first, live; opening one
/// marks it read.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc(this._getNotifications, this._markRead, this._watchChanges)
    : super(const NotificationsState()) {
    on<NotificationsFetched>(_onFetched);
    on<NotificationsChangesWatched>(_onChangesWatched);
    on<NotificationsOpened>(_onOpened);
    on<NotificationsAllRead>(_onAllRead);
  }

  final GetNotificationsUseCase _getNotifications;
  final MarkNotificationsReadUseCase _markRead;
  final WatchNotificationChangesUseCase _watchChanges;

  Future<void> _onFetched(
    NotificationsFetched event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(status: NotificationsStatus.loading));
    final result = await _getNotifications(const NoParams());
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: NotificationsStatus.success,
            notifications: data,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: NotificationsStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  /// A new notification goes on top; a changed one (e.g. read on another
  /// device) is replaced where it is.
  Future<void> _onChangesWatched(
    NotificationsChangesWatched event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await _watchChanges(const NoParams());
    if (result case Success(data: final changes)) {
      await emit.forEach(
        changes,
        onData: (change) {
          if (change case Success(:final data)) {
            final changed = data.notification;
            final known = state.notifications.any((n) => n.id == changed.id);
            return state.copyWith(
              notifications: [
                if (data.isNew && !known) changed,
                for (final n in state.notifications)
                  n.id == changed.id ? changed : n,
              ],
            );
          }
          return state;
        },
      );
    }
  }

  /// Read on the spot; the list shows it read even if saving it failed, and
  /// the next load shows the truth.
  Future<void> _onOpened(
    NotificationsOpened event,
    Emitter<NotificationsState> emit,
  ) async {
    final opened = event.notification;
    if (!opened.isRead) {
      emit(state.copyWith(notifications: _readAll(only: opened.id)));
      await _markRead([opened.id]);
    }
  }

  Future<void> _onAllRead(
    NotificationsAllRead event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state.unreadCount == 0) return;
    emit(state.copyWith(notifications: _readAll()));
    await _markRead(null);
  }

  /// The list with [only] (or every unread one) marked read now.
  List<UserNotification> _readAll({String? only}) {
    final now = DateTime.now().toUtc();
    return [
      for (final n in state.notifications)
        if (!n.isRead && (only == null || n.id == only))
          UserNotification(
            id: n.id,
            title: n.title,
            body: n.body,
            data: n.data,
            readAt: now,
            createdAt: n.createdAt,
          )
        else
          n,
    ];
  }
}
