import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/marketplace/shared/datasource/models/marketplace_address_model.dart';
import 'package:watad/features/marketplace/shared/datasource/models/marketplace_order_model.dart';
import 'package:watad/features/marketplace/shared/datasource/models/order_line_model.dart';
import 'package:watad/features/marketplace/shared/datasource/models/order_status_change_model.dart';
import 'package:watad/features/marketplace/shared/domain/entities/card_payment.dart';
import 'package:watad/features/marketplace/shared/domain/entities/checkout_request.dart';

abstract interface class OrdersRemoteDataSource {
  Future<List<MarketplaceAddressModel>> getMyAddresses();

  Future<int> countMyUnpaidOrders();

  Future<String> checkout(CheckoutRequest request);

  Future<MarketplaceOrderModel?> getOrder(String orderId);

  Future<List<MarketplaceOrderModel>> getMyPurchases();

  Future<List<OrderLineModel>> getOrderLines(String orderId);

  Future<List<OrderStatusChangeModel>> getStatusHistory(String orderId);

  Future<void> cancelOrder(String orderId);

  Future<void> confirmDelivered(String orderId);

  Future<void> simulatePayment(
    String orderId,
    CardPayment payment, {
    required bool succeed,
  });
}

class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  const OrdersRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const String _orderColumns =
      'id, status, payment_method, total_amount, card_brand, card_last4, '
      'paid_at, created_at, my_role, buyer_id, buyer_name, buyer_avatar_path, '
      'seller_id, seller_name, seller_avatar_path, line_count, unit_count, '
      'can_review, delivery_address';

  @override
  Future<List<MarketplaceAddressModel>> getMyAddresses() async {
    final rows = await _client
        .from('v_my_addresses')
        .select('id, name, city, district, formatted_address')
        .order('created_at', ascending: false);
    return rows.map(MarketplaceAddressModel.fromJson).toList();
  }

  @override
  Future<int> countMyUnpaidOrders() async {
    final rows = await _client
        .from('v_my_orders')
        .select('id')
        .eq('my_role', 'buyer')
        .eq('status', 'pending_payment');
    return rows.length;
  }

  @override
  Future<String> checkout(CheckoutRequest request) {
    // The price is never sent: checkout() takes it from the listing.
    return _client.rpc<String>(
      'checkout',
      params: {
        'p_items': [
          for (final line in request.lines)
            {'item_id': line.itemId, 'quantity': line.quantity},
        ],
        'p_payment_method': request.method.toJson(),
        'p_address_id': request.addressId,
      },
    );
  }

  @override
  Future<MarketplaceOrderModel?> getOrder(String orderId) async {
    final row = await _client
        .from('v_my_orders')
        .select(_orderColumns)
        .eq('id', orderId)
        .maybeSingle();
    return row == null ? null : _toOrder(row);
  }

  @override
  Future<List<MarketplaceOrderModel>> getMyPurchases() async {
    final rows = await _client
        .from('v_my_orders')
        .select(_orderColumns)
        .eq('my_role', 'buyer')
        .order('created_at', ascending: false);
    return rows.map(_toOrder).toList();
  }

  @override
  Future<List<OrderLineModel>> getOrderLines(String orderId) async {
    final rows = await _client
        .from('v_order_items')
        .select('item_id, item_name, quantity, price_at_purchase, subtotal')
        .eq('order_id', orderId)
        .order('created_at');
    return rows.map(OrderLineModel.fromJson).toList();
  }

  @override
  Future<List<OrderStatusChangeModel>> getStatusHistory(String orderId) async {
    // Never the note: it may hold a server's or a person's own words.
    final rows = await _client
        .from('v_order_status_history')
        .select('old_status, new_status, changed_at')
        .eq('order_id', orderId)
        .order('changed_at');
    return rows.map(OrderStatusChangeModel.fromJson).toList();
  }

  @override
  Future<void> cancelOrder(String orderId) =>
      _client.rpc<void>('cancel_order', params: {'p_order_id': orderId});

  @override
  Future<void> confirmDelivered(String orderId) => _client.rpc<void>(
    'confirm_order_delivered',
    params: {'p_order_id': orderId},
  );

  @override
  Future<void> simulatePayment(
    String orderId,
    CardPayment payment, {
    required bool succeed,
  }) async {
    // DEMO ONLY (ARCHITECTURE.md §15): the brand and last 4 digits, never a
    // full card number or CVV.
    await _client.rpc<void>(
      'simulate_order_payment',
      params: {
        'p_order_id': orderId,
        'p_card_brand': payment.brand.value,
        'p_card_last4': payment.last4,
        'p_succeed': succeed,
      },
    );
  }

  MarketplaceOrderModel _toOrder(Map<String, dynamic> row) =>
      MarketplaceOrderModel.fromJson({
        ...row,
        'buyer_avatar_url': _avatarUrl(row['buyer_avatar_path'] as String?),
        'seller_avatar_url': _avatarUrl(row['seller_avatar_path'] as String?),
      });

  String? _avatarUrl(String? path) => path == null || path.isEmpty
      ? null
      : _client.storage.from('avatars').getPublicUrl(path);
}
