import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_marketplace_item_use_case.dart';

import '../../../../../helpers/fake_marketplace_repository.dart';

void main() {
  late FakeMarketplaceRepository repository;
  late GetMarketplaceItemUseCase getItem;

  setUp(() {
    repository = FakeMarketplaceRepository();
    getItem = GetMarketplaceItemUseCase(repository);
  });

  MarketplaceItem? itemOf(Result<MarketplaceItem?> result) => switch (result) {
    Success(:final data) => data,
    Failed() => throw StateError('expected a success'),
  };

  test('returns a listed item, and my own hidden one', () async {
    expect(itemOf(await getItem('i-steel'))?.id, 'i-steel');
    expect(itemOf(await getItem('i-wood-hidden'))?.id, 'i-wood-hidden');
  });

  test('no row, or removed by an admin, is unavailable (null)', () async {
    expect(itemOf(await getItem('i-missing')), isNull);
    expect(itemOf(await getItem('i-removed')), isNull);
  });

  test('passes on a failure', () async {
    repository.itemResult = const Failed(NetworkFailure());

    expect(await getItem('i-steel'), isA<Failed<MarketplaceItem?>>());
  });
}
