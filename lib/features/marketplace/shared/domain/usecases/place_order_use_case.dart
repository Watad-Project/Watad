import 'package:watad/core/enums/payment_method.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/checkout_problem.dart';
import 'package:watad/features/marketplace/shared/domain/entities/checkout_request.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/entities/placed_order.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/cart_repository.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/marketplace_repository.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/orders_repository.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/review_checkout_use_case.dart';

/// «تأكيد الطلب»: checks the lines once more against the server, then calls
/// `checkout()` and takes exactly those lines out of the cart.
///
/// Anything `checkout()` would refuse without a code (5 unpaid orders, too
/// little stock, my own item, two sellers) comes back as a
/// [ValidationFailure] with its own message instead.
class PlaceOrderUseCase implements UseCase<PlacedOrder, CheckoutRequest> {
  const PlaceOrderUseCase(this._cart, this._items, this._orders);

  final CartRepository _cart;
  final MarketplaceRepository _items;
  final OrdersRepository _orders;

  @override
  Future<Result<PlacedOrder>> call(CheckoutRequest request) async {
    if (request.method == PaymentMethod.bankTransfer) {
      return const Failed(
        ValidationFailure('marketplace.checkout.error_method'),
      );
    }
    if (request.addressId.isEmpty) {
      return const Failed(
        ValidationFailure('marketplace.checkout.error_address'),
      );
    }
    if (request.lines.isEmpty) return _refuse(CheckoutProblem.empty);
    if (request.lines.length > ReviewCheckoutUseCase.maxLines) {
      return _refuse(CheckoutProblem.tooManyLines);
    }

    final List<MarketplaceItem> items;
    switch (await _items.getItemsByIds([
      for (final line in request.lines) line.itemId,
    ])) {
      case Success(:final data):
        items = data;
      case Failed(:final failure):
        return Failed(failure);
    }
    if (_problemOf(request, items) case final problem?) return _refuse(problem);

    switch (await _orders.countMyUnpaidOrders()) {
      case Success(:final data)
          when data >= ReviewCheckoutUseCase.maxUnpaidOrders:
        return _refuse(CheckoutProblem.tooManyUnpaidOrders);
      case Success():
        break;
      case Failed(:final failure):
        return Failed(failure);
    }

    final String orderId;
    switch (await _orders.checkout(request)) {
      case Success(:final data):
        orderId = data;
      case Failed(:final failure):
        return Failed(failure);
    }

    // The order exists now: a cart that can't be cleared doesn't undo it.
    final ordered = {for (final line in request.lines) line.itemId};
    final cleared = switch (await _cart.getLines()) {
      Success(:final data) => await _cart.saveLines([
        for (final line in data)
          if (!ordered.contains(line.itemId)) line,
      ]),
      Failed(:final failure) => Failed<void>(failure),
    };
    return Success(
      PlacedOrder(orderId: orderId, cartCleared: cleared is Success<void>),
    );
  }

  static CheckoutProblem? _problemOf(
    CheckoutRequest request,
    List<MarketplaceItem> items,
  ) {
    final byId = {for (final item in items) item.id: item};
    final found = [for (final line in request.lines) ?byId[line.itemId]];
    if (found.any((item) => item.isMine)) return CheckoutProblem.ownItem;
    if (found.length < request.lines.length ||
        found.any(
          (item) => !item.isActive || item.isRemoved || item.stockQuantity <= 0,
        )) {
      return CheckoutProblem.unavailable;
    }
    if (found.any((item) => item.sellerId != request.sellerId)) {
      return CheckoutProblem.mixedSellers;
    }
    for (final line in request.lines) {
      final item = byId[line.itemId]!;
      if (line.quantity > item.stockQuantity) {
        return CheckoutProblem.notEnoughStock;
      }
      if (item.price != line.priceWhenAdded) return CheckoutProblem.changed;
    }
    return null;
  }

  static Result<PlacedOrder> _refuse(CheckoutProblem problem) =>
      Failed(ValidationFailure(problem.messageKey));
}
