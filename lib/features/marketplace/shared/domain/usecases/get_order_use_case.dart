import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_order.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/orders_repository.dart';

/// One of my orders by id; not found when I'm neither its buyer nor its
/// seller.
class GetOrderUseCase implements UseCase<MarketplaceOrder, String> {
  const GetOrderUseCase(this._orders);

  final OrdersRepository _orders;

  @override
  Future<Result<MarketplaceOrder>> call(String orderId) async {
    return switch (await _orders.getOrder(orderId)) {
      Success(:final data?) => Success(data),
      Success() => const Failed(NotFoundFailure()),
      Failed(:final failure) => Failed(failure),
    };
  }
}
