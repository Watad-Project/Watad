import 'package:watad/core/enums/order_status.dart';
import 'package:watad/core/enums/payment_method.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/card_payment.dart';
import 'package:watad/features/marketplace/shared/domain/entities/checkout_request.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_address.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_order.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_address.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_line.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_role.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_status_change.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/orders_repository.dart';

const MarketplaceAddress fakeHomeAddress = MarketplaceAddress(
  id: 'a-home',
  name: 'المنزل',
  city: 'المدينة المنورة',
  district: 'العزيزية',
  formattedAddress: '٢٤٥٠ شارع الملك عبدالله، العزيزية، المدينة المنورة ٤٢٣١١',
);

/// An order of mine, by default unpaid, bought by me with a credit card.
MarketplaceOrder fakeOrder({
  String id = '7c9e6679-7425-40de-944b-e07fc1f90ae7',
  OrderStatus status = OrderStatus.pendingPayment,
  PaymentMethod method = PaymentMethod.creditCard,
  OrderRole role = OrderRole.buyer,
  Money total = const Money.halalas(500000),
  String? cardBrand,
  String? cardLast4,
  DateTime? paidAt,
  bool canReview = false,
  DateTime? createdAt,
  OrderAddress? deliveryAddress = const OrderAddress(
    name: 'المنزل',
    city: 'المدينة المنورة',
    formattedAddress: '٢٤٥٠ شارع الملك عبدالله، العزيزية، المدينة المنورة',
  ),
}) => MarketplaceOrder(
  id: id,
  status: status,
  paymentMethod: method,
  total: total,
  myRole: role,
  buyerId: 'u-buyer',
  buyerName: 'خالد المطيري',
  sellerId: 'u-seller',
  sellerName: 'سارة العتيبي',
  lineCount: 1,
  unitCount: 2,
  createdAt: createdAt ?? DateTime.utc(2026, 11, 1, 9),
  cardBrand: cardBrand,
  cardLast4: cardLast4,
  paidAt: paidAt,
  canReview: canReview,
  deliveryAddress: deliveryAddress,
);

/// Two units of «حديد تسليح» at 2,500 SAR: the products of [fakeOrder].
const List<OrderLine> fakeOrderLines = [
  OrderLine(
    itemId: 'i-steel',
    name: 'حديد تسليح ١٢ مم',
    quantity: 2,
    price: Money.halalas(250000),
    subtotal: Money.halalas(500000),
  ),
];

/// [order] with another [status], as the server would change it.
MarketplaceOrder orderWithStatus(
  MarketplaceOrder order,
  OrderStatus status, {
  bool? canReview,
}) => MarketplaceOrder(
  id: order.id,
  status: status,
  paymentMethod: order.paymentMethod,
  total: order.total,
  myRole: order.myRole,
  buyerId: order.buyerId,
  buyerName: order.buyerName,
  buyerAvatarUrl: order.buyerAvatarUrl,
  sellerId: order.sellerId,
  sellerName: order.sellerName,
  sellerAvatarUrl: order.sellerAvatarUrl,
  lineCount: order.lineCount,
  unitCount: order.unitCount,
  createdAt: order.createdAt,
  cardBrand: order.cardBrand,
  cardLast4: order.cardLast4,
  paidAt: order.paidAt,
  canReview: canReview ?? order.canReview,
  deliveryAddress: order.deliveryAddress,
);

/// A hand-written [OrdersRepository] (APP_ARCHITECTURE.md §16). It keeps
/// [orders] by id, creates one on [checkout], and pays it like
/// `simulate_order_payment()`: `succeed: false` is refused as a
/// [ServerFailure] (`payment_declined` has no code). [cancelOrder],
/// [confirmDelivered], and [markShipped] change the status and add a step
/// to the timeline, like `cancel_order()`, `confirm_order_delivered()`,
/// and `mark_order_shipped()`.
class FakeOrdersRepository implements OrdersRepository {
  List<MarketplaceAddress> addresses = [fakeHomeAddress];
  int unpaidCount = 0;
  final Map<String, MarketplaceOrder> orders = {};

  /// The products and the timeline of each order; [fakeOrderLines] and one
  /// «بانتظار الدفع» step when an order has none.
  final Map<String, List<OrderLine>> lines = {};
  final Map<String, List<OrderStatusChange>> history = {};

  /// The id [checkout] gives the next order.
  String nextOrderId = '0b1c2d3e-4f50-6172-8394-a5b6c7d8e9f0';

  Result<List<MarketplaceAddress>>? addressesResult;
  Result<int>? unpaidResult;
  Result<String>? checkoutResult;
  Result<MarketplaceOrder?>? orderResult;
  Result<void>? paymentResult;
  Result<List<MarketplaceOrder>>? purchasesResult;
  Result<List<MarketplaceOrder>>? salesResult;
  Result<List<OrderLine>>? linesResult;
  Result<List<OrderStatusChange>>? historyResult;
  Result<void>? cancelResult;
  Result<void>? confirmResult;
  Result<void>? shipResult;

  /// The orders [cancelOrder], [confirmDelivered], and [markShipped] were
  /// called for.
  final List<String> cancelled = [];
  final List<String> confirmed = [];
  final List<String> shipped = [];

  /// Every [checkout] and [simulatePayment] call, in order: all that ever
  /// reaches the repository.
  final List<CheckoutRequest> checkouts = [];
  final List<({String orderId, CardPayment payment, bool succeed})> payments =
      [];

  @override
  Future<Result<List<MarketplaceAddress>>> getMyAddresses() async =>
      addressesResult ?? Success(List.unmodifiable(addresses));

  @override
  Future<Result<int>> countMyUnpaidOrders() async =>
      unpaidResult ?? Success(unpaidCount);

  @override
  Future<Result<String>> checkout(CheckoutRequest request) async {
    checkouts.add(request);
    if (checkoutResult case final result?) return result;
    orders[nextOrderId] = fakeOrder(id: nextOrderId, method: request.method);
    return Success(nextOrderId);
  }

  @override
  Future<Result<MarketplaceOrder?>> getOrder(String orderId) async =>
      orderResult ?? Success(orders[orderId]);

  @override
  Future<Result<List<MarketplaceOrder>>> getMyPurchases() async {
    if (purchasesResult case final result?) return result;
    final mine = [
      for (final order in orders.values)
        if (order.myRole == OrderRole.buyer) order,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Success(mine);
  }

  @override
  Future<Result<List<MarketplaceOrder>>> getMySales() async {
    if (salesResult case final result?) return result;
    final mine = [
      for (final order in orders.values)
        if (order.myRole == OrderRole.seller) order,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Success(mine);
  }

  @override
  Future<Result<List<OrderLine>>> getOrderLines(String orderId) async =>
      linesResult ?? Success(lines[orderId] ?? fakeOrderLines);

  @override
  Future<Result<List<OrderStatusChange>>> getStatusHistory(
    String orderId,
  ) async => historyResult ?? Success(_historyOf(orderId));

  List<OrderStatusChange> _historyOf(String orderId) =>
      history[orderId] ??
      [
        OrderStatusChange(
          newStatus: OrderStatus.pendingPayment,
          changedAt: DateTime.utc(2026, 11, 1, 9),
        ),
      ];

  @override
  Future<Result<void>> cancelOrder(String orderId) async {
    cancelled.add(orderId);
    if (cancelResult case final result?) return result;
    return _change(orderId, OrderStatus.cancelled);
  }

  @override
  Future<Result<void>> confirmDelivered(String orderId) async {
    confirmed.add(orderId);
    if (confirmResult case final result?) return result;
    return _change(orderId, OrderStatus.delivered, canReview: true);
  }

  @override
  Future<Result<void>> markShipped(String orderId) async {
    shipped.add(orderId);
    if (shipResult case final result?) return result;
    return _change(orderId, OrderStatus.shipped);
  }

  Result<void> _change(String orderId, OrderStatus status, {bool? canReview}) {
    final order = orders[orderId];
    if (order == null) return const Failed(NotFoundFailure());
    history[orderId] = [
      ..._historyOf(orderId),
      OrderStatusChange(
        oldStatus: order.status,
        newStatus: status,
        changedAt: DateTime.utc(2026, 11, 2, 12),
      ),
    ];
    orders[orderId] = orderWithStatus(order, status, canReview: canReview);
    return const Success(null);
  }

  @override
  Future<Result<void>> simulatePayment(
    String orderId,
    CardPayment payment, {
    required bool succeed,
  }) async {
    payments.add((orderId: orderId, payment: payment, succeed: succeed));
    if (paymentResult case final result?) return result;
    final order = orders[orderId];
    if (order == null) return const Failed(NotFoundFailure());
    if (!succeed) return const Failed(ServerFailure());
    orders[orderId] = fakeOrder(
      id: order.id,
      status: OrderStatus.paid,
      method: order.paymentMethod,
      total: order.total,
      cardBrand: payment.brand.value,
      cardLast4: payment.last4,
      paidAt: DateTime.utc(2026, 11, 1, 10),
    );
    return const Success(null);
  }
}
