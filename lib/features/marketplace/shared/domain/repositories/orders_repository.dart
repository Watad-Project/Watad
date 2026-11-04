import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/card_payment.dart';
import 'package:watad/features/marketplace/shared/domain/entities/checkout_request.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_address.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_order.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_line.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_status_change.dart';

/// Marketplace orders: checkout, the demo payment, reading them back and
/// the buyer's and seller's actions (`v_my_orders`, `v_order_items`,
/// `v_order_status_history`, `v_my_addresses`, `checkout`,
/// `simulate_order_payment`, `cancel_order`, `mark_order_shipped`,
/// `confirm_order_delivered`).
abstract interface class OrdersRepository {
  /// The buyer's saved addresses, newest first.
  Future<Result<List<MarketplaceAddress>>> getMyAddresses();

  /// My orders as the buyer that still await payment.
  Future<Result<int>> countMyUnpaidOrders();

  /// Creates the order and reserves its stock; returns the new order's id.
  Future<Result<String>> checkout(CheckoutRequest request);

  /// One of my orders, or null when I can't see it.
  Future<Result<MarketplaceOrder?>> getOrder(String orderId);

  /// The orders I bought, newest first.
  Future<Result<List<MarketplaceOrder>>> getMyPurchases();

  /// The orders of my listings, newest first.
  Future<Result<List<MarketplaceOrder>>> getMySales();

  /// The products of one of my orders, in the order they were added.
  Future<Result<List<OrderLine>>> getOrderLines(String orderId);

  /// The status changes of one of my orders, oldest first.
  Future<Result<List<OrderStatusChange>>> getStatusHistory(String orderId);

  /// Cancels an unpaid order; its stock goes back to the listings.
  Future<Result<void>> cancelOrder(String orderId);

  /// The seller marks a paid order as shipped.
  Future<Result<void>> markShipped(String orderId);

  /// The buyer says a paid or shipped order arrived.
  Future<Result<void>> confirmDelivered(String orderId);

  /// DEMO ONLY: pays [orderId] when [succeed] is true; when it is false the
  /// server refuses it as declined. Only the brand and last 4 digits are
  /// sent (ARCHITECTURE.md §15).
  Future<Result<void>> simulatePayment(
    String orderId,
    CardPayment payment, {
    required bool succeed,
  });
}
