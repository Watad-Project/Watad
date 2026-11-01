import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/notification_group.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_notification_change.dart';
import 'package:watad/features/settings/shared/domain/usecases/delete_account_use_case.dart';
import 'package:watad/features/settings/shared/domain/usecases/get_settings_overview_use_case.dart';
import 'package:watad/features/settings/shared/domain/usecases/set_notification_preference_use_case.dart';
import 'package:watad/features/settings/shared/domain/usecases/sign_out_use_case.dart';
import 'package:watad/features/settings/shared/presentation/bloc/settings_bloc.dart';

import '../../../../../helpers/fake_settings_repository.dart';

SettingsBloc _bloc(FakeSettingsRepository repository) => SettingsBloc(
  GetSettingsOverviewUseCase(repository),
  SetNotificationPreferenceUseCase(repository),
  SignOutUseCase(repository),
  DeleteAccountUseCase(repository),
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('loads the settings', () async {
    final bloc = _bloc(FakeSettingsRepository())..add(const SettingsFetched());
    await _settle();

    expect(bloc.state.status, SettingsStatus.success);
    expect(bloc.state.overview?.isContractor, isTrue);
    await bloc.close();
  });

  test('a failed load keeps the failure', () async {
    final repository = FakeSettingsRepository()
      ..overviewResult = const Failed(NetworkFailure());
    final bloc = _bloc(repository)..add(const SettingsFetched());
    await _settle();

    expect(bloc.state.status, SettingsStatus.failure);
    expect(bloc.state.failure, isA<NetworkFailure>());
    await bloc.close();
  });

  test('a switch saves at once', () async {
    final repository = FakeSettingsRepository();
    final bloc = _bloc(repository)..add(const SettingsFetched());
    await _settle();

    bloc.add(
      const SettingsNotificationToggled(
        SettingsNotificationChange(NotificationGroup.messages, enabled: false),
      ),
    );
    await _settle();

    expect(bloc.state.overview?.isOn(NotificationGroup.messages), isFalse);
    expect(repository.calls, ['messages off']);
  });

  test('a switch whose save fails goes back and says why', () async {
    final repository = FakeSettingsRepository()
      ..setResult = const Failed(NetworkFailure());
    final bloc = _bloc(repository)..add(const SettingsFetched());
    await _settle();

    bloc.add(
      const SettingsNotificationToggled(
        SettingsNotificationChange(NotificationGroup.tasks, enabled: false),
      ),
    );
    await _settle();

    expect(bloc.state.overview?.isOn(NotificationGroup.tasks), isTrue);
    expect(bloc.state.notice?.key, 'errors.network');
    await bloc.close();
  });

  test('signing out ends signed out', () async {
    final repository = FakeSettingsRepository();
    final bloc = _bloc(repository)..add(const SettingsSignOutRequested());
    await _settle();

    expect(bloc.state.isSignedOut, isTrue);
    expect(repository.calls, ['sign out']);
    await bloc.close();
  });

  test('a blocked delete says why and stays signed in', () async {
    final repository = FakeSettingsRepository()
      ..blockersResult = const Success({});
    repository.deleteResult = const Failed(ServerFailure());
    final bloc = _bloc(repository)..add(const SettingsAccountDeleteRequested());
    await _settle();

    expect(bloc.state.isSignedOut, isFalse);
    expect(bloc.state.busyAction, isNull);
    expect(bloc.state.notice?.key, 'errors.server');
    await bloc.close();
  });
}
