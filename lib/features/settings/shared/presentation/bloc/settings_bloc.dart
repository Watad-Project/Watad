import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_notification_change.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_overview.dart';
import 'package:watad/features/settings/shared/domain/usecases/delete_account_use_case.dart';
import 'package:watad/features/settings/shared/domain/usecases/get_settings_overview_use_case.dart';
import 'package:watad/features/settings/shared/domain/usecases/set_notification_preference_use_case.dart';
import 'package:watad/features/settings/shared/domain/usecases/sign_out_use_case.dart';

part 'settings_event.dart';
part 'settings_state.dart';

/// The settings screen: what comes from the server, the notification
/// switches (saved at once, put back when the save fails), signing out and
/// closing the account.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(
    this._getOverview,
    this._setNotification,
    this._signOut,
    this._deleteAccount,
  ) : super(const SettingsState()) {
    on<SettingsFetched>(_onFetched);
    on<SettingsNotificationToggled>(_onToggled);
    on<SettingsSignOutRequested>(
      (event, emit) => _leave(emit, SettingsAction.signOut, _signOut.call),
    );
    on<SettingsAccountDeleteRequested>(
      (event, emit) => _leave(emit, SettingsAction.delete, _deleteAccount.call),
    );
  }

  final GetSettingsOverviewUseCase _getOverview;
  final SetNotificationPreferenceUseCase _setNotification;
  final SignOutUseCase _signOut;
  final DeleteAccountUseCase _deleteAccount;

  Future<void> _onFetched(
    SettingsFetched event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    final result = await _getOverview(const NoParams());
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: SettingsStatus.success,
            overview: () => data,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: SettingsStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  Future<void> _onToggled(
    SettingsNotificationToggled event,
    Emitter<SettingsState> emit,
  ) async {
    final overview = state.overview;
    if (overview == null) return;
    final change = event.change;
    final before = overview.isOn(change.group);
    // The switch moves at once; the server decides whether it stays.
    emit(
      state.copyWith(
        overview: () => overview.withNotification(change.group, change.enabled),
      ),
    );
    final result = await _setNotification(change);
    if (result case Failed(:final failure)) {
      emit(
        state.copyWith(
          overview: () =>
              state.overview?.withNotification(change.group, before),
          notice: () => SettingsNotice(failure.messageKey),
        ),
      );
    }
  }

  Future<void> _leave(
    Emitter<SettingsState> emit,
    SettingsAction action,
    Future<Result<void>> Function(NoParams) run,
  ) async {
    if (state.busyAction != null) return;
    emit(state.copyWith(busyAction: () => action));
    final result = await run(const NoParams());
    switch (result) {
      case Success():
        emit(state.copyWith(busyAction: () => null, isSignedOut: true));
      case Failed(:final failure):
        emit(
          state.copyWith(
            busyAction: () => null,
            notice: () => SettingsNotice(failure.messageKey),
          ),
        );
    }
  }
}
