import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/notifications/shared/domain/entities/notification_target.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification.dart';
import 'package:watad/features/notifications/shared/domain/usecases/get_unread_notifications_count_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/start_push_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/watch_notification_changes_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/watch_notification_taps_use_case.dart';

part 'notifications_bell_event.dart';
part 'notifications_bell_state.dart';

/// The bell on each role's home, alive for the whole session: the unread
/// count, live; each notification arriving while the app is open, shown on
/// top of any screen (no push then); and the pushes the user taps.
/// Starting it asks permission to notify; OneSignal itself starts at launch
/// (`startAppServices()`).
class NotificationsBellBloc
    extends Bloc<NotificationsBellEvent, NotificationsBellState> {
  NotificationsBellBloc(
    this._getUnreadCount,
    this._startPush,
    this._watchChanges,
    this._watchTaps,
  ) : super(const NotificationsBellState()) {
    on<NotificationsBellStarted>(_onStarted);
    on<NotificationsBellCountRequested>(_onCountRequested);
    on<NotificationsBellChangesWatched>(_onChangesWatched);
    on<NotificationsBellTapsWatched>(_onTapsWatched);
  }

  final GetUnreadNotificationsCountUseCase _getUnreadCount;
  final StartPushUseCase _startPush;
  final WatchNotificationChangesUseCase _watchChanges;
  final WatchNotificationTapsUseCase _watchTaps;

  Future<void> _onStarted(
    NotificationsBellStarted event,
    Emitter<NotificationsBellState> emit,
  ) async {
    // Listening first, so a tap that opened the app isn't missed.
    add(const NotificationsBellTapsWatched());
    add(const NotificationsBellChangesWatched());
    await _refreshCount(emit);
    // Push is a bonus: without it (no permission, no App ID) the bell works.
    await _startPush(const NoParams());
  }

  Future<void> _onCountRequested(
    NotificationsBellCountRequested event,
    Emitter<NotificationsBellState> emit,
  ) => _refreshCount(emit);

  Future<void> _refreshCount(Emitter<NotificationsBellState> emit) async {
    final result = await _getUnreadCount(const NoParams());
    if (result case Success(:final data)) {
      emit(state.copyWith(unreadCount: data));
    }
  }

  /// A new notification is shown; any change (new, read here or on another
  /// device) counts again, so the bell is right.
  Future<void> _onChangesWatched(
    NotificationsBellChangesWatched event,
    Emitter<NotificationsBellState> emit,
  ) async {
    final result = await _watchChanges(const NoParams());
    if (result case Success(data: final changes)) {
      await emit.forEach(
        changes,
        onData: (change) {
          if (change case Success(:final data)) {
            add(const NotificationsBellCountRequested());
            if (data.isNew) {
              return state.copyWith(arrived: () => data.notification);
            }
          }
          return state;
        },
      );
    }
  }

  Future<void> _onTapsWatched(
    NotificationsBellTapsWatched event,
    Emitter<NotificationsBellState> emit,
  ) async {
    final result = await _watchTaps(const NoParams());
    if (result case Success(data: final taps)) {
      await emit.forEach(
        taps,
        onData: (tap) => switch (tap) {
          Success(:final data) => state.copyWith(tapped: () => data),
          Failed() => state,
        },
      );
    }
  }
}
