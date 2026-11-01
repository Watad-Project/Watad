import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/marketplace_category.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/create_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_my_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/update_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/my_item_form_bloc.dart';

import '../../../../../helpers/fake_marketplace_repository.dart';

void main() {
  late FakeMarketplaceRepository repository;
  late MyItemFormBloc bloc;

  setUp(() {
    repository = FakeMarketplaceRepository();
    bloc = MyItemFormBloc(
      GetMyMarketplaceItemUseCase(repository),
      CreateMarketplaceItemUseCase(repository),
      UpdateMarketplaceItemUseCase(repository),
    );
  });

  tearDown(() => bloc.close());

  test('validates required fields and creates a new listing', () async {
    bloc.add(const MyItemFormStarted());
    await pumpEventQueue();
    expect(bloc.state.status, MyItemFormStatus.ready);

    // Submitting empty form shows validation errors without calling repo.
    bloc.add(const MyItemFormSubmitted());
    await pumpEventQueue();
    expect(bloc.state.showValidationErrors, isTrue);
    expect(bloc.state.nameErrorKey, 'marketplace.my_items_name_error');
    expect(bloc.state.priceErrorKey, 'marketplace.my_items_price_error');
    expect(bloc.state.stockErrorKey, 'marketplace.my_items_stock_error');
    expect(bloc.state.categoryErrorKey, 'marketplace.my_items_category_error');

    // Fill valid fields and up to 6 photos.
    bloc
      ..add(const MyItemFormNameChanged('طوب أحمر مفرغ'))
      ..add(const MyItemFormDescriptionChanged('طوب عالي الجودة للبناء'))
      ..add(const MyItemFormPriceChanged('12.50'))
      ..add(const MyItemFormStockChanged('500'))
      ..add(
        const MyItemFormCategoryChanged(MarketplaceCategory.buildingMaterials),
      )
      ..add(const MyItemFormPhotoAdded('u-business/marketplace/new/1.jpg'))
      ..add(const MyItemFormPhotoAdded('u-business/marketplace/new/2.jpg'))
      ..add(const MyItemFormPhotoRemoved(0));
    await pumpEventQueue();

    expect(bloc.state.isValid, isTrue);
    expect(bloc.state.parsedPrice, const Money.halalas(1250));
    expect(bloc.state.parsedStock, 500);
    expect(bloc.state.photos, ['u-business/marketplace/new/2.jpg']);

    bloc.add(const MyItemFormSubmitted());
    await pumpEventQueue();

    expect(bloc.state.status, MyItemFormStatus.saved);
    expect(bloc.state.savedItem?.name, 'طوب أحمر مفرغ');
  });

  test('loads an existing listing and updates it', () async {
    bloc.add(const MyItemFormStarted(itemId: 'i-cement'));
    await pumpEventQueue();

    expect(bloc.state.status, MyItemFormStatus.ready);
    expect(bloc.state.name, 'أسمنت أبيض ٥٠ كجم');
    expect(bloc.state.priceText, '45');
    expect(bloc.state.stockText, '120');

    bloc
      ..add(const MyItemFormPriceChanged('50'))
      ..add(const MyItemFormSubmitted());
    await pumpEventQueue();

    expect(bloc.state.status, MyItemFormStatus.saved);
    expect(bloc.state.savedItem?.price, const Money.halalas(5000));
  });

  test('keeps an admin-removed listing read-only and ignores submit', () async {
    bloc.add(const MyItemFormStarted(itemId: 'i-removed'));
    await pumpEventQueue();

    expect(bloc.state.isRemoved, isTrue);
    expect(bloc.state.removalReason, 'صور غير مطابقة للمنتج المعروض');

    bloc.add(const MyItemFormSubmitted());
    await pumpEventQueue();
    expect(bloc.state.status, MyItemFormStatus.ready);
  });

  test('emits failure when loading or submitting fails', () async {
    repository.myItemResult = const Failed(NetworkFailure());
    bloc.add(const MyItemFormStarted(itemId: 'i-cement'));
    await pumpEventQueue();

    expect(bloc.state.status, MyItemFormStatus.failure);
    expect(bloc.state.loadFailure, isA<NetworkFailure>());

    // Now test submit failure on a fresh start.
    repository.myItemResult = null;
    repository.saveResult = const Failed(ServerFailure());
    bloc
      ..add(const MyItemFormStarted(itemId: 'i-cement'))
      ..add(const MyItemFormSubmitted());
    await pumpEventQueue();

    expect(bloc.state.status, MyItemFormStatus.ready);
    expect(bloc.state.submitFailure, isA<ServerFailure>());
  });
}
