import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/notifications/shared/domain/entities/notification_target.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification.dart';
import 'package:watad/features/notifications/shared/domain/usecases/get_unread_notifications_count_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/start_push_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/watch_new_notifications_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/watch_notification_taps_use_case.dart';

part 'notifications_bell_event.dart';
part 'notifications_bell_state.dart';

/// The bell on each home: the unread count, each notification arriving while
/// the app is open (shown in the app, no push), and the pushes the user taps.
/// Starting it asks permission to notify; OneSignal itself starts at launch
/// (`startAppServices()`).
class NotificationsBellBloc
    extends Bloc<NotificationsBellEvent, NotificationsBellState> {
  NotificationsBellBloc(
    this._getUnreadCount,
    this._startPush,
    this._watchNew,
    this._watchTaps,
  ) : super(const NotificationsBellState()) {
    on<NotificationsBellStarted>(_onStarted);
    on<NotificationsBellCountRequested>(_onCountRequested);
    on<NotificationsBellArrivalsWatched>(_onArrivalsWatched);
    on<NotificationsBellTapsWatched>(_onTapsWatched);
  }

  final GetUnreadNotificationsCountUseCase _getUnreadCount;
  final StartPushUseCase _startPush;
  final WatchNewNotificationsUseCase _watchNew;
  final WatchNotificationTapsUseCase _watchTaps;

  Future<void> _onStarted(
    NotificationsBellStarted event,
    Emitter<NotificationsBellState> emit,
  ) async {
    // Listening first, so a tap that opened the app isn't missed.
    add(const NotificationsBellTapsWatched());
    add(const NotificationsBellArrivalsWatched());
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

  Future<void> _onArrivalsWatched(
    NotificationsBellArrivalsWatched event,
    Emitter<NotificationsBellState> emit,
  ) async {
    final result = await _watchNew(const NoParams());
    if (result case Success(data: final arrivals)) {
      await emit.forEach(
        arrivals,
        onData: (arrival) => switch (arrival) {
          Success(:final data) => state.copyWith(
            unreadCount: state.unreadCount + 1,
            arrived: () => data,
          ),
          Failed() => state,
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
