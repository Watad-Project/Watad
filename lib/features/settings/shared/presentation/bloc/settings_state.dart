part of 'settings_bloc.dart';

enum SettingsStatus { initial, loading, success, failure }

/// Signing out or closing the account, while it's being sent.
enum SettingsAction { signOut, delete }

/// A message to show once, as a translation key.
final class SettingsNotice {
  const SettingsNotice(this.key);

  final String key;
}

final class SettingsState {
  const SettingsState({
    this.status = SettingsStatus.initial,
    this.overview,
    this.failure,
    this.busyAction,
    this.isSignedOut = false,
    this.notice,
  });

  final SettingsStatus status;

  /// Kept while it loads again.
  final SettingsOverview? overview;

  /// Why the settings couldn't load.
  final Failure? failure;

  final SettingsAction? busyAction;

  /// Signed out (also after closing the account): the page goes to login.
  final bool isSignedOut;
  final SettingsNotice? notice;

  SettingsState copyWith({
    SettingsStatus? status,
    SettingsOverview? Function()? overview,
    Failure? Function()? failure,
    SettingsAction? Function()? busyAction,
    bool? isSignedOut,
    SettingsNotice? Function()? notice,
  }) {
    return SettingsState(
      status: status ?? this.status,
      overview: overview == null ? this.overview : overview(),
      failure: failure == null ? this.failure : failure(),
      busyAction: busyAction == null ? this.busyAction : busyAction(),
      isSignedOut: isSignedOut ?? this.isSignedOut,
      notice: notice == null ? this.notice : notice(),
    );
  }
}
