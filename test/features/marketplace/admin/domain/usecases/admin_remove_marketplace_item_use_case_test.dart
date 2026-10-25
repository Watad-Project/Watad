import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_removal.dart';
import 'package:watad/features/marketplace/admin/domain/usecases/admin_remove_marketplace_item_use_case.dart';

import '../../../../../helpers/fake_admin_marketplace_repository.dart';

void main() {
  late FakeAdminMarketplaceRepository repository;

  setUp(() => repository = FakeAdminMarketplaceRepository());

  Future<Result<void>> remove(AdminMarketplaceItem item, String reason) =>
      AdminRemoveMarketplaceItemUseCase(repository)(
        AdminMarketplaceRemoval(item: item, reason: reason),
      );

  Matcher refused(String key) => isA<Failed<void>>().having(
    (f) => f.failure,
    'failure',
    isA<ValidationFailure>().having((f) => f.messageKey, 'key', key),
  );

  test('removes with the trimmed reason', () async {
    expect(await remove(fakeLiveItem, '  سعر مضلل '), isA<Success<void>>());
    // A hidden item can be removed too.
    expect(await remove(fakeHiddenItem, 'مخالف'), isA<Success<void>>());
    expect(repository.calls, [
      'remove i-live: سعر مضلل',
      'remove i-hidden: مخالف',
    ]);
  });

  test('refuses what the database refuses, each with its message', () async {
    expect(
      await remove(fakeRemovedItem, 'سبب'),
      refused('marketplace.error_already_removed'),
    );
    expect(await remove(fakeLiveItem, ' '), refused('common.reason_required'));
    expect(
      await remove(fakeLiveItem, 'س' * 1001),
      refused('marketplace.error_reason_too_long'),
    );
    expect(repository.calls, isEmpty);
  });
}
