import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/card_payment.dart';
import 'package:watad/features/marketplace/shared/domain/entities/checkout_request.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_address.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_order.dart';

/// Marketplace orders: checkout, the demo payment and reading them back
/// (`v_my_orders`, `v_my_addresses`, `checkout`, `simulate_order_payment`).
abstract interface class OrdersRepository {
  /// The buyer's saved addresses, newest first.
  Future<Result<List<MarketplaceAddress>>> getMyAddresses();

  /// My orders as the buyer that still await payment.
  Future<Result<int>> countMyUnpaidOrders();

  /// Creates the order and reserves its stock; returns the new order's id.
  Future<Result<String>> checkout(CheckoutRequest request);

  /// One of my orders, or null when I can't see it.
  Future<Result<MarketplaceOrder?>> getOrder(String orderId);

  /// DEMO ONLY: pays [orderId] when [succeed] is true; when it is false the
  /// server refuses it as declined. Only the brand and last 4 digits are
  /// sent (ARCHITECTURE.md §15).
  Future<Result<void>> simulatePayment(
    String orderId,
    CardPayment payment, {
    required bool succeed,
  });
}
