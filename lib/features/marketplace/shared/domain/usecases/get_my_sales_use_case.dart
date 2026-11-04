import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/my_orders.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/orders_repository.dart';

/// «مبيعاتي»: the orders of my listings, newest first.
class GetMySalesUseCase implements UseCase<MyOrders, NoParams> {
  const GetMySalesUseCase(this._orders);

  final OrdersRepository _orders;

  @override
  Future<Result<MyOrders>> call([NoParams params = const NoParams()]) async {
    return switch (await _orders.getMySales()) {
      Success(:final data) => Success(MyOrders(data)),
      Failed(:final failure) => Failed(failure),
    };
  }
}
