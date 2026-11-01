import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_delete_blocker.dart';
import 'package:watad/features/settings/shared/domain/usecases/delete_account_use_case.dart';

import '../../../../../helpers/fake_settings_repository.dart';

void main() {
  test('closes the account, then signs out', () async {
    final repository = FakeSettingsRepository();

    final result = await DeleteAccountUseCase(repository)(const NoParams());

    expect(result, isA<Success<void>>());
    expect(repository.calls, ['delete', 'sign out']);
  });

  test('says which thing stops it, and closes nothing', () async {
    Future<String?> keyOf(Set<SettingsDeleteBlocker> blockers) async {
      final repository = FakeSettingsRepository()
        ..blockersResult = Success(blockers);
      final result = await DeleteAccountUseCase(repository)(const NoParams());
      expect(repository.calls, isEmpty);
      return switch (result) {
        Failed(:final failure) => failure.messageKey,
        Success() => null,
      };
    }

    expect(
      await keyOf({SettingsDeleteBlocker.activeProjects}),
      'settings.delete_blocked_projects',
    );
    expect(
      await keyOf({SettingsDeleteBlocker.activeOrders}),
      'settings.delete_blocked_orders',
    );
  });

  test('a refused delete does not sign out', () async {
    final repository = FakeSettingsRepository()
      ..deleteResult = const Failed(PermissionFailure());

    final result = await DeleteAccountUseCase(repository)(const NoParams());

    expect(result, isA<Failed<void>>());
    expect(repository.calls, ['delete']);
  });
}
