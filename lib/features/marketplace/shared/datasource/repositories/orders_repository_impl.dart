import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/marketplace/shared/datasource/remote/orders_remote_data_source.dart';
import 'package:watad/features/marketplace/shared/domain/entities/card_payment.dart';
import 'package:watad/features/marketplace/shared/domain/entities/checkout_request.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_address.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_order.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_line.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_status_change.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/orders_repository.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  const OrdersRepositoryImpl(this._remote);

  final OrdersRemoteDataSource _remote;

  @override
  Future<Result<List<MarketplaceAddress>>> getMyAddresses() =>
      guardSupabaseCall(_remote.getMyAddresses);

  @override
  Future<Result<int>> countMyUnpaidOrders() =>
      guardSupabaseCall(_remote.countMyUnpaidOrders);

  @override
  Future<Result<String>> checkout(CheckoutRequest request) =>
      guardSupabaseCall(() => _remote.checkout(request));

  @override
  Future<Result<MarketplaceOrder?>> getOrder(String orderId) =>
      guardSupabaseCall(() => _remote.getOrder(orderId));

  @override
  Future<Result<List<MarketplaceOrder>>> getMyPurchases() =>
      guardSupabaseCall(_remote.getMyPurchases);

  @override
  Future<Result<List<OrderLine>>> getOrderLines(String orderId) =>
      guardSupabaseCall(() => _remote.getOrderLines(orderId));

  @override
  Future<Result<List<OrderStatusChange>>> getStatusHistory(String orderId) =>
      guardSupabaseCall(() => _remote.getStatusHistory(orderId));

  @override
  Future<Result<void>> cancelOrder(String orderId) =>
      guardSupabaseCall(() => _remote.cancelOrder(orderId));

  @override
  Future<Result<void>> confirmDelivered(String orderId) =>
      guardSupabaseCall(() => _remote.confirmDelivered(orderId));

  @override
  Future<Result<void>> simulatePayment(
    String orderId,
    CardPayment payment, {
    required bool succeed,
  }) => guardSupabaseCall(
    () => _remote.simulatePayment(orderId, payment, succeed: succeed),
  );
}
