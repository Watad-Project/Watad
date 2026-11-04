import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/payment_method.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';
import 'package:watad/features/marketplace/shared/domain/entities/checkout_problem.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_address.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/place_order_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/review_checkout_use_case.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/checkout_bloc.dart';

import '../../../../../helpers/fake_cart_repository.dart';
import '../../../../../helpers/fake_marketplace_repository.dart';
import '../../../../../helpers/fake_orders_repository.dart';

void main() {
  late FakeMarketplaceRepository items;
  late FakeCartRepository cart;
  late FakeOrdersRepository orders;

  CheckoutBloc buildBloc() => CheckoutBloc(
    ReviewCheckoutUseCase(cart, items, orders),
    PlaceOrderUseCase(cart, items, orders),
  );

  Future<CheckoutState> ready(CheckoutBloc bloc) => bloc.stream.firstWhere(
    (s) =>
        s.status == CheckoutStatus.ready || s.status == CheckoutStatus.failure,
  );

  setUp(() {
    items = FakeMarketplaceRepository()..items = [fakeSteelItem];
    cart = FakeCartRepository([
      const CartLine(
        itemId: 'i-steel',
        quantity: 2,
        priceWhenAdded: Money.halalas(250000),
      ),
    ]);
    orders = FakeOrdersRepository();
  });

  test('picks the first address, then places the order', () async {
    final bloc = buildBloc()..add(const CheckoutStarted('u-seller'));
    final loaded = await ready(bloc);
    expect(loaded.addressId, 'a-home');
    expect(loaded.canSubmit, isFalse, reason: 'no method picked yet');

    bloc
      ..add(const CheckoutMethodSelected(PaymentMethod.mada))
      ..add(const CheckoutSubmitted());
    final placed = await bloc.stream.firstWhere(
      (s) => s.submitStatus == CheckoutSubmitStatus.placed,
    );
    expect(placed.placed?.orderId, orders.nextOrderId);
    expect(orders.checkouts.single.method, PaymentMethod.mada);
    expect(cart.lines, isEmpty);
    await bloc.close();
  });

  test('a new address from the map is picked after reloading', () async {
    final bloc = buildBloc()..add(const CheckoutStarted('u-seller'));
    await ready(bloc);

    orders.addresses = [
      const MarketplaceAddress(
        id: 'a-new',
        name: 'المكتب',
        city: 'المدينة المنورة',
        district: 'قباء',
        formattedAddress: 'قباء، المدينة المنورة',
      ),
      fakeHomeAddress,
    ];
    bloc.add(const CheckoutAddressAdded('a-new'));
    final state = await bloc.stream.firstWhere((s) => s.addressId == 'a-new');
    expect(state.review?.addresses, hasLength(2));
    await bloc.close();
  });

  test('5 unpaid orders: the problem shows and nothing can be sent', () async {
    orders.unpaidCount = 5;
    final bloc = buildBloc()..add(const CheckoutStarted('u-seller'));

    final state = await ready(bloc);
    expect(state.review?.problem, CheckoutProblem.tooManyUnpaidOrders);
    bloc.add(const CheckoutMethodSelected(PaymentMethod.mada));
    expect((await bloc.stream.first).canSubmit, isFalse);
    await bloc.close();
  });

  test('a refused order says why and reloads the review', () async {
    final bloc = buildBloc()..add(const CheckoutStarted('u-seller'));
    await ready(bloc);

    orders.checkoutResult = const Failed(ServerFailure());
    bloc
      ..add(const CheckoutMethodSelected(PaymentMethod.creditCard))
      ..add(const CheckoutSubmitted());
    final failed = await bloc.stream.firstWhere(
      (s) => s.submitStatus == CheckoutSubmitStatus.failed,
    );
    expect(failed.submitFailure, isA<ServerFailure>());
    await bloc.close();
  });

  test('a review that cannot load is a failure', () async {
    orders.addressesResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(const CheckoutStarted('u-seller'));

    final state = await ready(bloc);
    expect(state.status, CheckoutStatus.failure);
    await bloc.close();
  });
}
