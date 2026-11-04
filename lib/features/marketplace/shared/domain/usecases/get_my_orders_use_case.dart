import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/my_orders.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/orders_repository.dart';

/// «طلباتي»: the orders I bought, newest first.
class GetMyOrdersUseCase implements UseCase<MyOrders, NoParams> {
  const GetMyOrdersUseCase(this._orders);

  final OrdersRepository _orders;

  @override
  Future<Result<MyOrders>> call([NoParams params = const NoParams()]) async {
    return switch (await _orders.getMyPurchases()) {
      Success(:final data) => Success(MyOrders(data)),
      Failed(:final failure) => Failed(failure),
    };
  }
}
